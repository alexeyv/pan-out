#!/bin/bash
#
# run-tests.sh — exercises hold-timer.py against the cook skill's I/O matrix.
#
# hold-timer.py resolves chime.sh and speak.sh relative to its own directory,
# so the suite copies the script into a scratch dir next to stub audio scripts.
# Every sound the timer would make is recorded to audio.log instead of played:
# the run is silent and every audio decision is assertable.
#
# Rows are real elapsed-time tests (including two suspend/resume rows), so the
# whole suite takes about a minute. Nothing outside the scratch dir is touched.
#
# Usage: bash test/timer/run-tests.sh

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TIMER_SRC="$REPO_ROOT/skills/panout-cook/bin/hold-timer.py"

if [ ! -f "$TIMER_SRC" ]; then
    echo "cannot find hold-timer.py at $TIMER_SRC" >&2
    exit 1
fi

WORK="$(mktemp -d "${TMPDIR:-/tmp}/hold-timer-tests.XXXXXX")"
TIMER="$WORK/hold-timer.py"
AUDIO_LOG="$WORK/audio.log"
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
    [ -n "$TIMER_PID" ] && kill -CONT "$TIMER_PID" 2>/dev/null
    [ -n "$TIMER_PID" ] && kill -KILL "$TIMER_PID" 2>/dev/null
    rm -rf "$WORK"
}
trap cleanup EXIT

# --- fixtures ---------------------------------------------------------------

cp "$TIMER_SRC" "$TIMER"

cat > "$WORK/chime.sh" <<'STUB'
#!/bin/sh
# stub chime.sh — records the request instead of playing a sound
printf 'chime %s\n' "$*" >> "$(dirname "$0")/audio.log"
STUB

cat > "$WORK/speak.sh" <<'STUB'
#!/bin/sh
# stub speak.sh — records the request instead of speaking
printf 'speak %s\n' "$*" >> "$(dirname "$0")/audio.log"
STUB

chmod +x "$WORK/chime.sh" "$WORK/speak.sh"

# --- harness ----------------------------------------------------------------

begin() {
    ROW="$1"
    ROW_ERR=""
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
    START_EPOCH=$(date +%s)
    python3 "$TIMER" "$@" >"$OUT" 2>"$ERR" &
    TIMER_PID=$!
}

# Sets TIMER_STATUS. Cannot echo it — `wait` only works in the shell that
# owns the background job, never inside a command substitution.
stop_timer() {
    kill -TERM "$TIMER_PID" 2>/dev/null
    wait "$TIMER_PID"
    TIMER_STATUS=$?
    TIMER_PID=""
}

# Runs an assertion script over the stdout event lines. Prints problems, if any.
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

begin "--help prints the contract"
python3 "$TIMER" --help >"$OUT" 2>"$ERR"
expect_eq 0 "$?" "exit status"
expect_ge "$(count_containing "$OUT" 'Schedule')" 1 "help mentions Schedule"
expect_ge "$(count_containing "$OUT" '--audio-mode')" 1 "help lists --audio-mode"
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
    if not -1 <= slack <= 1:
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
if types[:1] == ["gap"] and lines[0]["seconds"] < 8:
    out.append("gap reported only %ss for a 10s suspend" % lines[0]["seconds"])
for event in lines[1:]:
    if "late_by" not in event:
        out.append("%s not marked late" % event["message"])
print("; ".join(out))
')
[ -z "$problems" ] || problem "$problems"
end

begin "long suspend re-anchors with nothing due"
start_timer '{"version":1,"events":[{"after":30,"type":"complete","message":"later"}]}' \
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
elif lines[0]["seconds"] < 15:
    out.append("gap reported only %ss for an 18s suspend" % lines[0]["seconds"])
print("; ".join(out))
')
[ -z "$problems" ] || problem "$problems"
end

begin "completion nag repeats until killed, then goes silent"
start_timer '{"version":1,"events":[{"after":1,"type":"complete","message":"done"}]}' \
    --audio-mode chime --tick-seconds 0 --nag-seconds 1
sleep 4
expect_ge "$(count_containing "$ERR" 'nag #')" 2 "nags logged to stderr"
expect_ge "$(count_matching "$AUDIO_LOG" 'chime alarm')" 2 "alarms played"
expect_eq 1 "$(count_lines "$OUT")" "stdout stays at 1 line while nagging"
alarms_at_kill=$(count_matching "$AUDIO_LOG" 'chime alarm')
stop_timer
expect_eq 0 "$TIMER_STATUS" "exit status after SIGTERM"
sleep 2
expect_eq "$alarms_at_kill" "$(count_matching "$AUDIO_LOG" 'chime alarm')" "alarms after kill"
end

begin "tts mode speaks the speak field; --nag-seconds 0 stays quiet"
start_timer '{"version":1,"events":[{"after":1,"type":"complete",
  "message":"written form","speak":"spoken form"}]}' \
    --audio-mode tts --tick-seconds 0 --nag-seconds 0
sleep 3
if ! kill -0 "$TIMER_PID" 2>/dev/null; then
    problem "timer exited on its own after the last event"
fi
stop_timer
expect_eq 0 "$TIMER_STATUS" "exit status after SIGTERM"
expect_ge "$(count_matching "$AUDIO_LOG" 'speak spoken form')" 1 "spoken text"
expect_eq 0 "$(count_containing "$ERR" 'nag #')" "nags with --nag-seconds 0"
end

begin "schedule from a file, out-of-order events sorted"
printf '%s' '{"version":1,"events":[
  {"after":2,"type":"countdown","message":"second"},
  {"after":1,"type":"countdown","message":"first"}]}' > "$WORK/schedule.json"
start_timer "$WORK/schedule.json" --audio-mode silent --tick-seconds 0
sleep 3
stop_timer
expect_eq 0 "$TIMER_STATUS" "exit status after SIGTERM"
problems=$(check_events '
import json, sys
lines = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
got = [e["message"] for e in lines]
print("order was %s" % got if got != ["first", "second"] else "")
')
[ -z "$problems" ] || problem "$problems"
end

begin "unusable schedules emit one error line and exit 1"
while IFS= read -r bad; do
    [ -n "$bad" ] || continue
    case "$bad" in
        EMPTY) bad="" ;;
    esac
    : > "$AUDIO_LOG"
    python3 "$TIMER" "$bad" --audio-mode silent >"$OUT" 2>"$ERR"
    status=$?
    label="$(printf '%.34s' "${bad:-<empty>}")"
    expect_eq 1 "$status" "exit status for $label"
    expect_eq 1 "$(count_lines "$OUT")" "stdout line count for $label"
    expect_eq 1 "$(count_containing "$OUT" '"type":"error"')" "error line for $label"
    expect_ge "$(count_lines "$ERR")" 1 "stderr detail for $label"
done <<'BAD'
EMPTY
{
{"version":1}
{"version":1,"events":[]}
{"version":2,"events":[{"after":1,"type":"t","message":"m"}]}
{"version":1,"events":[{"type":"t","message":"m"}]}
{"version":1,"events":[{"after":-5,"type":"t","message":"m"}]}
{"version":1,"events":[{"after":1,"type":"t"}]}
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
