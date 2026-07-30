#!/bin/bash
#
# run-tests.sh — exercises hold-timer.py against the cook skill's I/O matrix.
#
# hold-timer.py resolves chime.sh and speak.sh relative to its own directory,
# so the suite copies the script into a scratch dir next to stub audio scripts.
# Every sound the timer would make is recorded to audio.log instead of played:
# the run is silent and every audio decision is assertable. Writing a duration
# into the scratch dir's `slow` file makes the stubs sleep that long and then
# append an ENDED line, which is how the suite proves a sound was truly cut off.
#
# Rows are real elapsed-time tests (including suspend/resume and wedged-audio
# rows), so the whole suite takes about 90 seconds. Nothing outside the scratch
# dir is touched.
#
# Usage: bash test/timer/run-tests.sh

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TIMER_SRC="$REPO_ROOT/skills/panout-cook/bin/hold-timer.py"

if [ ! -f "$TIMER_SRC" ]; then
    echo "cannot find hold-timer.py at $TIMER_SRC" >&2
    exit 1
fi

if ! WORK="$(mktemp -d "${TMPDIR:-/tmp}/hold-timer-tests.XXXXXX")" || [ ! -d "$WORK" ]; then
    echo "cannot create a scratch directory" >&2
    exit 1
fi

TIMER="$WORK/hold-timer.py"
AUDIO_LOG="$WORK/audio.log"
SLOW_MARKER="$WORK/slow"
OUT="$WORK/stdout.txt"
ERR="$WORK/stderr.txt"

TIMER_PID=""
TIMER_STATUS=0
PASSED=0
FAILED=0
FAILED_ROWS=""
ROW=""
ROW_ERR=""
START_EPOCH=0

cleanup() {
    if [ -n "$TIMER_PID" ]; then
        kill -CONT "$TIMER_PID" 2>/dev/null
        kill -KILL "$TIMER_PID" 2>/dev/null
    fi
    rm -rf "$WORK"
}
trap cleanup EXIT

# --- fixtures ---------------------------------------------------------------

cp "$TIMER_SRC" "$TIMER"

write_stub() { # filename log-label
    cat > "$WORK/$1" <<STUB
#!/bin/sh
# stub $1 — records the request instead of making a sound
DIR="\$(dirname "\$0")"
printf '$2 %s\n' "\$*" >> "\$DIR/audio.log"
if [ -f "\$DIR/slow" ]; then
    sleep "\$(cat "\$DIR/slow")"
    printf '$2 ENDED %s\n' "\$*" >> "\$DIR/audio.log"
fi
STUB
    chmod +x "$WORK/$1"
}

write_stub chime.sh chime
write_stub speak.sh speak

# --- harness ----------------------------------------------------------------

begin() {
    ROW="$1"
    ROW_ERR=""
    rm -f "$SLOW_MARKER"
    : > "$AUDIO_LOG"
    : > "$OUT"
    : > "$ERR"
}

problem() {
    ROW_ERR="${ROW_ERR}${ROW_ERR:+; }$1"
}

expect_eq() { # expected actual label
    [ "$1" = "$2" ] || problem "$3: expected '$1', got '$2'"
}

expect_ge() { # actual minimum label
    if ! [ "$1" -ge "$2" ] 2>/dev/null; then
        problem "$3: expected at least $2, got $1"
    fi
}

end() {
    if [ -z "$ROW_ERR" ]; then
        PASSED=$((PASSED + 1))
        printf '  PASS  %s\n' "$ROW"
    else
        FAILED=$((FAILED + 1))
        FAILED_ROWS="${FAILED_ROWS}
  - ${ROW}: ${ROW_ERR}"
        printf '  FAIL  %s\n        %s\n' "$ROW" "$ROW_ERR"
    fi
}

count_lines() { awk 'END {print NR}' "$1"; }

count_matching() { awk -v pat="$2" '$0 == pat {n++} END {print n+0}' "$1"; }

count_containing() { awk -v pat="$2" 'index($0, pat) {n++} END {print n+0}' "$1"; }

start_timer() {
    if [ -n "$TIMER_PID" ]; then
        kill -CONT "$TIMER_PID" 2>/dev/null
        kill -KILL "$TIMER_PID" 2>/dev/null
        wait "$TIMER_PID" 2>/dev/null
        TIMER_PID=""
        problem "a previous timer was still running when this row started"
    fi
    START_EPOCH=$(date +%s)
    python3 "$TIMER" "$@" >"$OUT" 2>"$ERR" &
    TIMER_PID=$!
}

# Waits for the timer to exit and cannot hang the suite: the watchdog CONTs a
# stopped process (delivering any pending TERM), then KILLs it. `wait` has to
# run in this shell — a command substitution cannot see the background job.
await_exit() { # grace_seconds
    local watchdog
    ( sleep "$1"
      kill -CONT "$TIMER_PID" 2>/dev/null
      kill -KILL "$TIMER_PID" 2>/dev/null ) &
    watchdog=$!
    wait "$TIMER_PID"
    TIMER_STATUS=$?
    kill "$watchdog" 2>/dev/null
    wait "$watchdog" 2>/dev/null
    TIMER_PID=""
}

stop_timer() {
    kill -TERM "$TIMER_PID" 2>/dev/null
    await_exit 8
}

# Runs an assertion script over the stdout event lines; prints problems, if any.
check_events() { # python-source
    python3 -c "$1" "$OUT" "$START_EPOCH" 2>&1
}

echo "hold-timer tests (scratch: $WORK)"
echo

# --- rows -------------------------------------------------------------------

begin "script compiles"
python3 -m py_compile "$TIMER" >"$ERR" 2>&1
expect_eq 0 "$?" "py_compile exit"
end

begin "--help shows the contract and the cadence defaults"
python3 "$TIMER" --help >"$OUT" 2>"$ERR"
expect_eq 0 "$?" "exit status"
expect_ge "$(count_containing "$OUT" 'Schedule')" 1 "help mentions Schedule"
expect_ge "$(count_containing "$OUT" '--audio-mode')" 1 "help lists --audio-mode"
expect_ge "$(count_containing "$OUT" 'default: 60')" 1 "help shows the 60s tick default"
expect_ge "$(count_containing "$OUT" 'default: 45')" 1 "help shows the 45s nag default"
end

begin "schedule and duration validation"
# stderr stays out of the capture — the module logs legitimately to it.
problems=$(python3 - "$TIMER" 2>"$ERR" <<'PY'
import importlib.util, json, sys

spec = importlib.util.spec_from_file_location("ht", sys.argv[1])
ht = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ht)
out = []


def event(**kw):
    base = {"after": 1, "type": "progress", "message": "m"}
    base.update(kw)
    return json.dumps({"version": 1, "events": [base]})


def rejects(label, text):
    try:
        ht.parse_schedule(text)
    except ht.ScheduleError:
        return
    out.append("accepted %s" % label)


rejects("NaN after", event(after=float("nan")))
rejects("Infinity after",
        '{"version":1,"events":[{"after":Infinity,"type":"t","message":"m"}]}')
rejects("boolean after", event(after=True))
rejects("string after", event(after="1"))
rejects("negative after", event(after=-1))
rejects("boolean version",
        '{"version":true,"events":[{"after":1,"type":"t","message":"m"}]}')
rejects("float version",
        '{"version":1.0,"events":[{"after":1,"type":"t","message":"m"}]}')
rejects("reserved type gap", event(type="gap"))
rejects("reserved type GAP", event(type="GAP"))
rejects("reserved type error", event(type="error"))
rejects("blank speak", event(speak="   "))
rejects("blank detail", event(detail=""))
rejects("blank message", event(message=" "))
rejects("JSON array", '[{"after":1}]')
rejects("oversized message", event(message="x" * 5000))
rejects("oversized unknown key", event(zzz="x" * 5000))

kept = ht.parse_schedule(event(fired_at=99, late_by=42))[0].payload
for key in ("fired_at", "late_by"):
    if key in kept:
        out.append("kept caller-supplied %s" % key)

order = [e.after for e in ht.parse_schedule(
    '{"version":1,"events":['
    '{"after":9,"type":"t","message":"late"},'
    '{"after":2,"type":"t","message":"early"}]}')]
if order != [2.0, 9.0]:
    out.append("sort order was %s" % order)

if ht.parse_schedule(event())[0].payload["speak"] != "m":
    out.append("speak did not default to message")

for seconds, want in ((30, "30s"), (60, "1 min"), (90, "1 min 30s"),
                      (3600, "1 h"), (3660, "1 h 1 min"), (28800, "8 h"),
                      (-90, "1 min 30s")):
    got = ht.fmt_duration(seconds)
    if got != want:
        out.append("fmt_duration(%s) = %r, wanted %r" % (seconds, got, want))

print("; ".join(out))
PY
)
status=$?
expect_eq 0 "$status" "validation script exit"
[ -z "$problems" ] || problem "$problems"
for bad in "--tick-seconds nan" "--tick-seconds inf" "--tick-seconds 0.5" \
           "--nag-seconds nan" "--nag-seconds -1" "--nag-seconds 0.2"; do
    # shellcheck disable=SC2086
    python3 "$TIMER" '{"version":1,"events":[{"after":1,"type":"t","message":"m"}]}' \
        --audio-mode silent $bad >"$OUT" 2>"$ERR"
    expect_eq 2 "$?" "usage exit for $bad"
done
end

begin "3 events fire in order, on time, silent"
start_timer '{"version":1,"events":[
  {"after":1,"type":"progress","message":"one"},
  {"after":2,"type":"progress","message":"two"},
  {"after":3,"type":"complete","message":"three"}]}' \
    --audio-mode silent --tick-seconds 0
sleep 5
stop_timer
expect_eq 0 "$TIMER_STATUS" "exit status after SIGTERM"
expect_eq 3 "$(count_lines "$OUT")" "stdout line count"
expect_eq 0 "$(count_lines "$AUDIO_LOG")" "audio calls in silent mode"
problems=$(check_events '
import json, sys
lines = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
start = int(sys.argv[2])
out = []
got = [e["message"] for e in lines]
if got != ["one", "two", "three"]:
    out.append("order was %s" % got)
for event, after in zip(lines, [1, 2, 3]):
    slack = event["fired_at"] - (start + after)
    if not 0 <= slack <= 2:
        out.append("%s fired %+ds off target" % (event["message"], slack))
print("; ".join(out))
')
[ -z "$problems" ] || problem "$problems"
end

begin "heartbeat ticks without touching stdout"
start_timer '{"version":1,"events":[{"after":30,"type":"complete","message":"done"}]}' \
    --audio-mode chime --tick-seconds 1
sleep 4
stop_timer
expect_eq 0 "$TIMER_STATUS" "exit status after SIGTERM"
expect_eq 0 "$(count_lines "$OUT")" "stdout stays empty between events"
expect_ge "$(count_matching "$AUDIO_LOG" 'chime tick')" 2 "tick count"
end

begin "chime mode plays alert on a fired event"
start_timer '{"version":1,"events":[{"after":1,"type":"progress","message":"ping"}]}' \
    --audio-mode chime --tick-seconds 0 --nag-seconds 0
await_exit 10
expect_eq 0 "$TIMER_STATUS" "exit status"
expect_eq 1 "$(count_lines "$OUT")" "stdout line count"
expect_ge "$(count_matching "$AUDIO_LOG" 'chime alert')" 1 "alert played for the event"
expect_eq 0 "$(count_matching "$AUDIO_LOG" 'chime tick')" "ticks with --tick-seconds 0"
end

begin "silent mode makes no sound, even while nagging"
start_timer '{"version":1,"events":[{"after":1,"type":"complete","message":"quiet"}]}' \
    --audio-mode silent --tick-seconds 1 --nag-seconds 1
sleep 4
stop_timer
expect_eq 0 "$TIMER_STATUS" "exit status after SIGTERM"
expect_eq 1 "$(count_lines "$OUT")" "stdout line count"
expect_eq 0 "$(count_lines "$AUDIO_LOG")" "audio calls in silent mode"
expect_ge "$(count_containing "$ERR" 'nag #')" 2 "nags logged to stderr"
end

begin "degree signs and em-dashes stay literal on stdout"
start_timer '{"version":1,"events":[{"after":1,"type":"ready-check",
  "message":"Bath at 63°C — ready check","detail":"Hold at 63°C — do not lift the lid.",
  "speak":"Bath holding at sixty-three."}]}' \
    --audio-mode silent --tick-seconds 0 --nag-seconds 0
await_exit 10
expect_eq 0 "$TIMER_STATUS" "exit status"
expect_ge "$(count_containing "$OUT" '63°C — ready check')" 1 "literal ° and — in message"
expect_ge "$(count_containing "$OUT" '63°C — do not lift')" 1 "literal ° and — in detail"
expect_eq 0 "$(count_containing "$OUT" 'u00b0')" "escaped degree sign on stdout"
end

begin "schedule file with apostrophes, invoked as SKILL.md documents"
cat > "$WORK/timer-schedule.json" <<'JSON'
{"version": 1, "events": [
  {"after": 1, "type": "preflight", "message": "Don't lift the lid yet",
   "detail": "Phase 3 is the sear. Don't touch the bag — it's still holding.",
   "speak": "Almost there. Don't lift the lid."}
]}
JSON
start_timer "$WORK/timer-schedule.json" --label "Bath hold" \
    --audio-mode tts --tick-seconds 0 --nag-seconds 0
await_exit 10
expect_eq 0 "$TIMER_STATUS" "exit status"
expect_eq 1 "$(count_lines "$OUT")" "stdout line count"
expect_ge "$(count_containing "$OUT" "Don't lift the lid yet")" 1 "apostrophe survived"
expect_ge "$(count_matching "$AUDIO_LOG" "speak Almost there. Don't lift the lid.")" 1 \
    "spoke the schedule's speak text"
end

begin "tts nag repeats alarm and the last event's speak text"
start_timer '{"version":1,"events":[
  {"after":1,"type":"progress","message":"not this one","speak":"first message"},
  {"after":2,"type":"complete","message":"bath done","speak":"Bath is done, come back."}]}' \
    --audio-mode tts --tick-seconds 0 --nag-seconds 1
sleep 6
expect_ge "$(count_containing "$ERR" 'nag #')" 2 "nags logged to stderr"
expect_ge "$(count_matching "$AUDIO_LOG" 'chime alarm')" 2 "alarms played"
# One announcement each, then every nag repeats the LAST event's text. A nag
# reaching for the wrong event would push the first message past its single
# announcement.
expect_ge "$(count_matching "$AUDIO_LOG" 'speak Bath is done, come back.')" 3 \
    "nag repeated the last event's text"
expect_eq 1 "$(count_matching "$AUDIO_LOG" 'speak first message')" \
    "times the stale message was spoken"
expect_eq 2 "$(count_lines "$OUT")" "stdout stays at 2 lines while nagging"
alarms_at_kill=$(count_matching "$AUDIO_LOG" 'chime alarm')
stop_timer
expect_eq 0 "$TIMER_STATUS" "exit status after SIGTERM"
sleep 2
expect_eq "$alarms_at_kill" "$(count_matching "$AUDIO_LOG" 'chime alarm')" "alarms after kill"
end

begin "in-flight sound is silenced, not just abandoned"
echo 5 > "$SLOW_MARKER"
start_timer '{"version":1,"events":[{"after":1,"type":"complete","message":"talk",
  "speak":"a long spoken sentence"}]}' \
    --audio-mode tts --tick-seconds 0 --nag-seconds 1
sleep 3
expect_ge "$(count_matching "$AUDIO_LOG" 'speak a long spoken sentence')" 1 \
    "announcement started"
stop_timer
expect_eq 0 "$TIMER_STATUS" "exit status after SIGTERM"
sleep 4
expect_eq 0 "$(count_containing "$AUDIO_LOG" 'ENDED')" "sound kept playing after stop"
end

begin "wedged audio cannot mute the completion alarm"
echo 20 > "$SLOW_MARKER"
start_timer '{"version":1,"events":[{"after":1,"type":"complete","message":"done",
  "speak":"bath complete"}]}' \
    --audio-mode tts --tick-seconds 0 --nag-seconds 1
sleep 5
expect_eq 0 "$(count_matching "$AUDIO_LOG" 'chime alarm')" "alarm while audio is wedged"
expect_ge "$(count_containing "$ERR" 'audio still busy')" 1 "suppression logged honestly"
sleep 9
expect_ge "$(count_containing "$ERR" 'wedged')" 1 "wedged child reported"
expect_ge "$(count_matching "$AUDIO_LOG" 'chime alarm')" 1 "alarm recovered after the kill"
stop_timer
expect_eq 0 "$TIMER_STATUS" "exit status after SIGTERM"
end

begin "suspend across two events: gap line first, nothing skipped"
start_timer '{"version":1,"events":[
  {"after":6,"type":"progress","message":"six"},
  {"after":8,"type":"complete","message":"eight"}]}' \
    --audio-mode silent --tick-seconds 0
sleep 2
kill -STOP "$TIMER_PID"
sleep 10
kill -CONT "$TIMER_PID"
sleep 2
stop_timer
expect_eq 0 "$TIMER_STATUS" "exit status after SIGTERM"
expect_eq 3 "$(count_lines "$OUT")" "stdout line count (gap + 2 events)"
problems=$(check_events '
import json, sys
lines = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
out = []
types = [e["type"] for e in lines]
if types != ["gap", "progress", "complete"]:
    out.append("sequence was %s" % types)
if types[:1] == ["gap"]:
    if lines[0]["seconds"] < 8:
        out.append("gap reported only %ss for a 10s suspend" % lines[0]["seconds"])
    if "overdue" not in lines[0]["message"]:
        out.append("gap message omitted the overdue events: %r" % lines[0]["message"])
for event in lines[1:]:
    if "late_by" not in event:
        out.append("%s not marked late" % event["message"])
print("; ".join(out))
')
[ -z "$problems" ] || problem "$problems"
end

begin "long suspend re-anchors with nothing due"
start_timer '{"version":1,"events":[{"after":40,"type":"complete","message":"later"}]}' \
    --audio-mode silent --tick-seconds 0
sleep 1
kill -STOP "$TIMER_PID"
sleep 18
kill -CONT "$TIMER_PID"
sleep 2
stop_timer
expect_eq 0 "$TIMER_STATUS" "exit status after SIGTERM"
expect_eq 1 "$(count_lines "$OUT")" "stdout line count (gap only)"
problems=$(check_events '
import json, sys
lines = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
out = []
if not lines or lines[0]["type"] != "gap":
    out.append("first line was %s" % (lines[0]["type"] if lines else "nothing"))
else:
    if lines[0]["seconds"] < 15:
        out.append("gap reported only %ss for an 18s suspend" % lines[0]["seconds"])
    if "nothing due" not in lines[0]["message"]:
        out.append("gap message was %r" % lines[0]["message"])
print("; ".join(out))
')
[ -z "$problems" ] || problem "$problems"
end

begin "missing audio scripts are reported, timing continues"
mkdir -p "$WORK/deaf"
cp "$TIMER_SRC" "$WORK/deaf/hold-timer.py"
START_EPOCH=$(date +%s)
python3 "$WORK/deaf/hold-timer.py" \
    '{"version":1,"events":[{"after":1,"type":"complete","message":"still counting"}]}' \
    --audio-mode tts --tick-seconds 0 --nag-seconds 0 >"$OUT" 2>"$ERR" &
TIMER_PID=$!
await_exit 10
expect_eq 0 "$TIMER_STATUS" "exit status"
expect_eq 2 "$(count_lines "$OUT")" "stdout lines (one error, one event)"
problems=$(check_events '
import json, sys
lines = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
out = []
types = [e["type"] for e in lines]
if types != ["error", "complete"]:
    out.append("sequence was %s" % types)
if types[:1] == ["error"] and lines[0].get("fatal") is not False:
    out.append("audio failure was marked fatal=%r" % lines[0].get("fatal"))
print("; ".join(out))
')
[ -z "$problems" ] || problem "$problems"
rm -rf "$WORK/deaf"
end

begin "audio that runs and fails is reported once, timing unaffected"
mkdir -p "$WORK/broken"
cp "$TIMER_SRC" "$WORK/broken/hold-timer.py"
for stub in chime speak; do
    printf '#!/bin/sh\nexit 7\n' > "$WORK/broken/$stub.sh"
    chmod +x "$WORK/broken/$stub.sh"
done
START_EPOCH=$(date +%s)
python3 "$WORK/broken/hold-timer.py" '{"version":1,"events":[
  {"after":1,"type":"progress","message":"first"},
  {"after":2,"type":"complete","message":"second"}]}' \
    --audio-mode tts --tick-seconds 1 --nag-seconds 0 >"$OUT" 2>"$ERR" &
TIMER_PID=$!
await_exit 10
expect_eq 0 "$TIMER_STATUS" "exit status"
expect_eq 3 "$(count_lines "$OUT")" "stdout lines (2 events + 1 error)"
expect_ge "$(count_containing "$ERR" 'audio script exited 7')" 2 "per-occurrence stderr detail"
problems=$(check_events '
import json, sys
lines = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
start = int(sys.argv[2])
out = []
types = [e["type"] for e in lines]
if types != ["progress", "complete", "error"]:
    out.append("sequence was %s" % types)
errors = [e for e in lines if e["type"] == "error"]
if len(errors) != 1:
    out.append("%d error lines, wanted exactly 1" % len(errors))
elif errors[0].get("fatal") is not False:
    out.append("audio failure marked fatal=%r" % errors[0].get("fatal"))
for event, after in zip(lines, [1, 2]):
    slack = event["fired_at"] - (start + after)
    if not 0 <= slack <= 2:
        out.append("%s fired %+ds off target" % (event["message"], slack))
print("; ".join(out))
')
[ -z "$problems" ] || problem "$problems"
rm -rf "$WORK/broken"
end

begin "oversized schedule fields are rejected before they reach the agent"
python3 -c "
import json, sys
json.dump({'version': 1, 'events': [
    {'after': 1, 'type': 'progress', 'message': 'x' * 5000}]}, open(sys.argv[1], 'w'))
" "$WORK/too-big.json"
python3 "$TIMER" "$WORK/too-big.json" --audio-mode silent >"$OUT" 2>"$ERR"
expect_eq 1 "$?" "exit status"
expect_eq 1 "$(count_lines "$OUT")" "stdout line count"
expect_eq 1 "$(count_containing "$OUT" '"fatal":true')" "fatal error line"
expect_ge "$(count_containing "$OUT" 'the limit is 4096')" 1 "error names the limit"
python3 -c "
import json, sys
json.dump({'version': 1, 'events': [
    {'after': 1, 'type': 'progress', 'message': 'ok', 'detail': 'y' * 4000}]},
    open(sys.argv[1], 'w'))
" "$WORK/within-cap.json"
start_timer "$WORK/within-cap.json" --audio-mode silent --tick-seconds 0 --nag-seconds 0
await_exit 10
expect_eq 0 "$TIMER_STATUS" "exit status with a 4000-character detail"
expect_eq 1 "$(count_lines "$OUT")" "stdout lines with a 4000-character detail"
end

begin "unusable schedules emit one fatal error line and exit 1"
while IFS= read -r bad; do
    [ -n "$bad" ] || continue
    case "$bad" in
        EMPTY) bad="" ;;
    esac
    python3 "$TIMER" "$bad" --audio-mode silent >"$OUT" 2>"$ERR"
    status=$?
    label="$(printf '%.40s' "${bad:-<empty>}")"
    expect_eq 1 "$status" "exit status for $label"
    expect_eq 1 "$(count_lines "$OUT")" "stdout line count for $label"
    expect_eq 1 "$(count_containing "$OUT" '"type":"error"')" "error line for $label"
    expect_eq 1 "$(count_containing "$OUT" '"fatal":true')" "fatal flag for $label"
    expect_ge "$(count_lines "$ERR")" 1 "stderr detail for $label"
done <<BAD
EMPTY
{
{"version":1}
{"version":1,"events":[]}
{"version":2,"events":[{"after":1,"type":"t","message":"m"}]}
{"version":1,"events":[{"type":"t","message":"m"}]}
{"version":1,"events":[{"after":-5,"type":"t","message":"m"}]}
{"version":1,"events":[{"after":true,"type":"t","message":"m"}]}
{"version":1,"events":[{"after":1,"type":"t"}]}
{"version":1,"events":[{"after":1,"type":"gap","message":"m"}]}
$WORK/no-such-schedule.json
BAD
end

# --- summary ----------------------------------------------------------------

echo
printf '%d passed, %d failed\n' "$PASSED" "$FAILED"
if [ "$FAILED" -gt 0 ]; then
    printf 'failures:%s\n' "$FAILED_ROWS"
    exit 1
fi
exit 0
