#!/bin/bash
#
# run-tests.sh — exercises cook-statusline.py against the cook skill's I/O matrix.
#
# Black box throughout: every row builds a fixture project (a sessions/ directory
# of state files with phase_end computed relative to now), pipes a statusline JSON
# payload into the real script, and asserts on the line it prints. Chaining rows
# point HOME at a fake home whose .claude/settings.json runs a stub, so the user's
# own statusline is never invoked and ~/.claude is never read.
#
# The banner carries a live wall clock and a live countdown, so assertions are
# per-field with a tolerance: the clock may be either side of a minute boundary,
# and an M:SS countdown may lose a second or two to process startup.
#
# One row deliberately runs a fault-injected copy of the script — a crash has a
# specified behavior (the chain still gets its turn, exit 0) and that is worth
# proving.
#
# Two rows wait on real timeouts, so the suite takes about 5 seconds. Nothing
# outside the scratch dir is touched.
#
# Usage: bash test/statusline/run-tests.sh

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT_SRC="$REPO_ROOT/skills/panout-cook/bin/cook-statusline.py"

if [ ! -f "$SCRIPT_SRC" ]; then
    echo "cannot find cook-statusline.py at $SCRIPT_SRC" >&2
    exit 1
fi

# Every row shells out to python3; without it the suite would report two dozen
# unrelated failures instead of the one thing that is actually wrong.
if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 not found on PATH — this suite runs the real script, so it cannot proceed" >&2
    exit 1
fi

if ! WORK="$(mktemp -d "${TMPDIR:-/tmp}/cook-statusline-tests.XXXXXX")" || [ ! -d "$WORK" ]; then
    echo "cannot create a scratch directory" >&2
    exit 1
fi

SCRIPT="$WORK/cook-statusline.py"
PROJECT="$WORK/project"
HOME_DIR="$WORK/home"
OUT="$WORK/stdout.txt"
ERR="$WORK/stderr.txt"
COUNTER="$WORK/chain-invocations.txt"

# Carried in the argv of the deliberately-hung stub so cleanup can find it even
# if the script under test failed to reap its process group.
HANG_MARKER="PANOUT_TEST_HANG_$$"

PASSED=0
FAILED=0
FAILED_ROWS=""
ROW=""
ROW_ERR=""
STATUS=0
LINE=""
CLOCK_BEFORE=""
CLOCK_AFTER=""
RUN_CWD=""

cleanup() {
    pkill -f "$HANG_MARKER" >/dev/null 2>&1
    rm -rf "$WORK"
}
trap cleanup EXIT

cp "$SCRIPT_SRC" "$SCRIPT"

# The suite must never inherit the guard from an outer chained run.
unset PANOUT_STATUSLINE_CHAIN

# --- harness ----------------------------------------------------------------

begin() {
    ROW="$1"
    ROW_ERR=""
    rm -rf "$PROJECT" "$HOME_DIR"
    mkdir -p "$PROJECT" "$HOME_DIR/.claude"
    RUN_CWD="$PROJECT"
    : > "$OUT"
    : > "$ERR"
}

problem() {
    ROW_ERR="${ROW_ERR}${ROW_ERR:+; }$1"
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

expect_eq() { # expected actual label
    [ "$1" = "$2" ] || problem "$3: expected '$1', got '$2'"
}

# Passes when the actual value matches any candidate — how a live clock and a
# ticking countdown are asserted without a flaky suite.
expect_any() { # actual label candidate...
    local actual="$1" label="$2" candidate
    shift 2
    for candidate in "$@"; do
        [ "$actual" = "$candidate" ] && return 0
    done
    problem "$label: expected one of [$*], got '$actual'"
}

expect_contains() { # haystack needle label
    case "$1" in
        *"$2"*) ;;
        *) problem "$3: '$1' does not contain '$2'" ;;
    esac
}

field() { # n  — the nth ' | '-separated field of the rendered line
    printf '%s\n' "$LINE" | awk -F' \\| ' -v n="$1" '{print $n}'
}

field_count() {
    printf '%s\n' "$LINE" | awk -F' \\| ' '{print NF}'
}

expect_clock() { # n
    expect_any "$(field "$1")" "wall clock" "$CLOCK_BEFORE" "$CLOCK_AFTER"
}

# The whole banner, tolerant of a minute boundary crossing mid-row.
expect_line_either_clock() { # label prefix suffix
    expect_any "$LINE" "$1" "$2$CLOCK_BEFORE$3" "$2$CLOCK_AFTER$3"
}

# --- fixtures ---------------------------------------------------------------

# ISO 8601 with a ±HHMM offset, the way the cook skill writes phase_end.
iso_offset() { # seconds-from-now
    python3 -c 'import datetime, sys
delta = datetime.timedelta(seconds=float(sys.argv[1]))
print((datetime.datetime.now().astimezone() + delta).strftime("%Y-%m-%dT%H:%M:%S%z"))' "$1"
}

set_mtime() { # path seconds-from-now
    python3 -c 'import os, sys, time
os.utime(sys.argv[1], (time.time() + float(sys.argv[2]),) * 2)' "$1" "$2"
}

sessions_dir() { mkdir -p "$PROJECT/sessions"; }

# A state file with the fields the statusline reads, plus the nested and
# irrelevant ones a real file carries — the parser has to ignore those.
session() { # name status protocol phase phase_index phase_end-literal
    sessions_dir
    cat > "$PROJECT/sessions/$1.md" <<EOF
---
protocol: $3
started: "2026-07-30T09:00:00-0700"
current_phase: $4
phase_index: $5
step_index: 1
phase_elapsed: 12
phase_start: "2026-07-30T09:12:00-0700"
phase_end: $6
scaled_to: "900g beef"
deviations: 1
timer_mode: monitor-timer
timer_task_id: null
last_sensor:
  tc_display: "89"
  ir_display: null
  status: "this nested key must not shadow the real one"
  timestamp: "2026-07-30T09:22:00-0700"
audio_mode: tts
status: $2
---

# Cook Session

## Log
- 09:00 — started
EOF
}

# A state file written verbatim — for the rows about fields that are missing
# rather than wrong.
session_file() { # name  <<< whole file on stdin
    sessions_dir
    cat > "$PROJECT/sessions/$1.md"
}

# A fake user-level statusline. Echoing stdin back proves the chained command
# receives the very bytes this script was given.
user_statusline() { # shell-body
    cat > "$HOME_DIR/chained.sh" <<EOF
#!/bin/sh
$1
EOF
    chmod +x "$HOME_DIR/chained.sh"
    cat > "$HOME_DIR/.claude/settings.json" <<EOF
{"model": "opus", "statusLine": {"type": "command", "command": "'$HOME_DIR/chained.sh'"}}
EOF
}

# The sidecar the help skill writes when it installs over a project statusline:
# the displaced command, which this script must prefer over the user's.
sidecar() { # json-body
    mkdir -p "$PROJECT/.claude"
    printf '%s\n' "$1" > "$PROJECT/.claude/panout-statusline.json"
}

project_statusline() { # shell-body — the command the sidecar points at
    cat > "$PROJECT/displaced.sh" <<EOF
#!/bin/sh
$1
EOF
    chmod +x "$PROJECT/displaced.sh"
    sidecar "{\"chain_to\": \"'$PROJECT/displaced.sh'\"}"
}

payload() { # cwd project_dir
    printf '{"hook_event_name":"Status","session_id":"t","cwd":"%s","model":{"id":"m","display_name":"Fable 5"},"workspace":{"current_dir":"%s","project_dir":"%s"},"version":"2.0.0"}' \
        "$1" "$1" "$2"
}

# --- runner -----------------------------------------------------------------

run() { # [script-path]
    local script="${1:-$SCRIPT}"
    CLOCK_BEFORE="$(date +%H:%M)"
    payload "$RUN_CWD" "$PROJECT" | HOME="$HOME_DIR" python3 "$script" >"$OUT" 2>"$ERR"
    STATUS=$?
    CLOCK_AFTER="$(date +%H:%M)"
    LINE="$(head -1 "$OUT")"
    expect_eq 0 "$STATUS" "exit status"
    [ -s "$OUT" ] || problem "stdout was empty"
}

echo "cook-statusline tests (scratch: $WORK)"
echo

# --- rows -------------------------------------------------------------------

begin "script compiles"
python3 -m py_compile "$SCRIPT" >"$ERR" 2>&1
expect_eq 0 "$?" "py_compile exit"
end

begin "--help prints the contract"
python3 "$SCRIPT" --help >"$OUT" 2>"$ERR"
expect_eq 0 "$?" "exit status"
expect_contains "$(cat "$OUT")" "statusLine" "help mentions the settings key"
expect_contains "$(cat "$OUT")" "min left" "help documents the timer slot"
end

begin "--help survives a docstring-stripped interpreter"
python3 -OO "$SCRIPT" --help >"$OUT" 2>"$ERR"
expect_eq 0 "$?" "exit status under -OO"
[ -s "$OUT" ] || problem "stdout was empty under -OO"
end

begin "active hold renders dish, phase, clock and countdown"
session cook-2026-07-30-beef-stew active beef-stew collagen-conversion 3 "\"$(iso_offset 1410)\""
run
expect_eq 4 "$(field_count)" "field count"
expect_eq "🍲 Beef Stew" "$(field 1)" "dish"
expect_eq "PHASE 3: Collagen Conversion" "$(field 2)" "phase"
expect_clock 3
expect_eq "23min left" "$(field 4)" "timer"
# The whole line, exactly as the spec writes it.
expect_line_either_clock "rendered banner" \
    "🍲 Beef Stew | PHASE 3: Collagen Conversion | " " | 23min left"
end

begin "countdown is computed at render time, not read from the file"
session cook-2026-07-30-beef-stew active beef-stew collagen-conversion 3 "\"$(iso_offset 3630)\""
run
expect_eq "60min left" "$(field 4)" "timer at t+60min"
sleep 1
session cook-2026-07-30-beef-stew active beef-stew collagen-conversion 3 "\"$(iso_offset 930)\""
run
expect_eq "15min left" "$(field 4)" "timer after phase_end moved in"
end

begin "final minutes switch to M:SS"
session cook-2026-07-30-beef-stew active beef-stew sear 4 "\"$(iso_offset 228)\""
run
expect_any "$(field 4)" "timer" "3:48 left" "3:47 left" "3:46 left"
end

begin "the 5-minute boundary picks the right format on each side"
session cook-2026-07-30-beef-stew active beef-stew sear 4 "\"$(iso_offset 303)\""
run
expect_eq "5min left" "$(field 4)" "timer just above the boundary"
session cook-2026-07-30-beef-stew active beef-stew sear 4 "\"$(iso_offset 299)\""
run
expect_any "$(field 4)" "timer just below the boundary" "4:59 left" "4:58 left" "4:57 left"
end

begin "overdue reads as time over, never as time left"
session cook-2026-07-30-beef-stew active beef-stew braise 3 "\"$(iso_offset -390)\""
run
expect_eq "+6min over" "$(field 4)" "timer"
end

begin "a few seconds over is +1min, never +0min"
session cook-2026-07-30-beef-stew active beef-stew braise 3 "\"$(iso_offset -3)\""
run
expect_eq "+1min over" "$(field 4)" "timer"
end

begin "a long overrun reads in hours, not in five-digit minutes"
session cook-2026-07-30-beef-stew active beef-stew braise 3 "\"$(iso_offset -3601)\""
run
expect_eq "+1h over" "$(field 4)" "timer just past the hour"
# Fresh file, ancient deadline: mtime is the newer of the two, so this is still
# an active cook — it must not read as "+660min over".
session cook-2026-07-30-beef-stew active beef-stew braise 3 "\"$(iso_offset -39600)\""
run
expect_eq "+11h over" "$(field 4)" "timer eleven hours over"
end

begin "a deadline years out is not rendered as a countdown"
user_statusline 'echo USER-LINE'
session cook-2026-07-30-beef-stew active beef-stew braise 3 "\"$(iso_offset 31536000)\""
run
expect_eq "USER-LINE" "$LINE" "line for a year-typo phase_end"
# The bound has to clear a real multi-day cure, or it costs honest cooks the banner.
session cook-2026-07-30-beef-stew active beef-stew cure 1 "\"$(iso_offset 259200)\""
run
expect_eq "🍲 Beef Stew" "$(field 1)" "dish on a three-day cure"
expect_any "$(field 4)" "timer on a three-day cure" "4320min left" "4319min left"
end

begin "open-ended phase omits the timer slot entirely"
session cook-2026-07-30-beef-stew active beef-stew reduce 5 "null"
run
expect_eq 3 "$(field_count)" "field count"
expect_eq "🍲 Beef Stew" "$(field 1)" "dish"
expect_eq "PHASE 5: Reduce" "$(field 2)" "phase"
expect_clock 3
end

begin "an active session nobody has touched for a day is over"
user_statusline 'echo USER-LINE'
session cook-2026-07-30-beef-stew active beef-stew prep 1 "null"
# Just inside the window: a long hold or an overnight brine is a real cook.
set_mtime "$PROJECT/sessions/cook-2026-07-30-beef-stew.md" -82800
run
expect_eq "🍲 Beef Stew" "$(field 1)" "dish at 23h since the last write"
# Just outside it: the model forgot to close this one, days ago.
set_mtime "$PROJECT/sessions/cook-2026-07-30-beef-stew.md" -90000
run
expect_eq "USER-LINE" "$LINE" "line at 25h since the last write"
expect_contains "$(cat "$ERR")" "stale" "staleness noted on stderr"
end

begin "a stale mtime with a live deadline is still an active cook"
user_statusline 'echo USER-LINE'
session cook-2026-07-30-beef-stew active beef-stew braise 3 "\"$(iso_offset 1410)\""
set_mtime "$PROJECT/sessions/cook-2026-07-30-beef-stew.md" -172800
run
expect_eq "🍲 Beef Stew" "$(field 1)" "dish"
expect_eq "23min left" "$(field 4)" "timer"
end

begin "multiple active sessions: newest mtime wins"
session cook-2026-07-28-old-cook active old-cook simmer 1 "\"$(iso_offset 1410)\""
session cook-2026-07-30-beef-stew active beef-stew collagen-conversion 3 "\"$(iso_offset 1410)\""
set_mtime "$PROJECT/sessions/cook-2026-07-28-old-cook.md" -3600
run
expect_eq "🍲 Beef Stew" "$(field 1)" "dish from the newest active session"
end

begin "identical mtimes resolve the same way on every refresh"
session cook-2026-07-30-a-first active a-first simmer 1 "\"$(iso_offset 1410)\""
session cook-2026-07-30-b-second active b-second simmer 1 "\"$(iso_offset 1410)\""
set_mtime "$PROJECT/sessions/cook-2026-07-30-a-first.md" -60
set_mtime "$PROJECT/sessions/cook-2026-07-30-b-second.md" -60
run
first_pick="$(field 1)"
run
expect_eq "$first_pick" "$(field 1)" "same dish across refreshes"
expect_eq "🍲 B Second" "$first_pick" "deterministic tiebreak"
end

begin "no active cook: chains to the user's statusline with the same stdin"
session cook-2026-07-30-beef-stew completed beef-stew collagen-conversion 3 "\"$(iso_offset 1410)\""
user_statusline 'printf "USER-LINE "; cat'
run
expect_contains "$LINE" "USER-LINE " "chained marker"
expect_contains "$LINE" '"project_dir"' "chained command saw the statusline JSON"
expect_contains "$LINE" '"display_name":"Fable 5"' "chained command saw the same bytes"
end

begin "closing a session hands the line straight back to the user's statusline"
session cook-2026-07-30-beef-stew active beef-stew collagen-conversion 3 "\"$(iso_offset 1410)\""
user_statusline 'echo USER-LINE'
run
expect_line_either_clock "banner while active" \
    "🍲 Beef Stew | PHASE 3: Collagen Conversion | " " | 23min left"
session cook-2026-07-30-beef-stew completed beef-stew collagen-conversion 3 "\"$(iso_offset 1410)\""
run
expect_eq "USER-LINE" "$LINE" "line after status: completed"
end

begin "the displaced project statusline is preferred over the user's"
sessions_dir
user_statusline 'echo USER-LINE'
project_statusline 'echo PROJECT-LINE'
run
expect_eq "PROJECT-LINE" "$LINE" "line from the sidecar command"
# A sidecar that is not readable JSON is "no chain here", never a crash.
sidecar '{"chain_to": '
run
expect_eq "USER-LINE" "$LINE" "line with a malformed sidecar"
sidecar '{"note": "no chain_to here"}'
run
expect_eq "USER-LINE" "$LINE" "line with a sidecar that carries no command"
end

begin "chained multi-line output passes through verbatim"
user_statusline 'printf "first line\nsecond line\n"'
run
expect_eq 2 "$(awk 'END {print NR}' "$OUT")" "line count"
expect_eq "first line" "$(sed -n 1p "$OUT")" "line 1"
expect_eq "second line" "$(sed -n 2p "$OUT")" "line 2"
end

begin "no sessions directory at all still chains"
user_statusline 'echo USER-LINE'
run
expect_eq "USER-LINE" "$LINE" "chained line"
end

begin "the user's settings file is never written"
session cook-2026-07-30-beef-stew active beef-stew collagen-conversion 3 "\"$(iso_offset 1410)\""
user_statusline 'echo USER-LINE'
before="$(cksum < "$HOME_DIR/.claude/settings.json")"
run
expect_eq "$before" "$(cksum < "$HOME_DIR/.claude/settings.json")" "checksum after a rendered banner"
session cook-2026-07-30-beef-stew completed beef-stew collagen-conversion 3 "\"$(iso_offset 1410)\""
run
expect_eq "$before" "$(cksum < "$HOME_DIR/.claude/settings.json")" "checksum after a chained line"
expect_eq 1 "$(ls -1 "$HOME_DIR/.claude" | wc -l | tr -d ' ')" "files in the fake ~/.claude"
end

begin "a cook who cd'd into a subdirectory keeps the banner"
session cook-2026-07-30-beef-stew active beef-stew collagen-conversion 3 "\"$(iso_offset 1410)\""
user_statusline 'echo USER-LINE'
mkdir -p "$PROJECT/protocols/drafts"
RUN_CWD="$PROJECT/protocols/drafts"
run
expect_eq "🍲 Beef Stew" "$(field 1)" "dish resolved from project_dir, not cwd"
expect_eq "23min left" "$(field 4)" "timer"
end

begin "a missing or unusable phase_index drops the prefix, not the phase"
user_statusline 'echo USER-LINE'
session_file cook-no-index <<EOF
---
protocol: beef-stew
current_phase: collagen-conversion
phase_end: null
status: active
---
EOF
run
expect_eq 3 "$(field_count)" "field count"
expect_eq "Collagen Conversion" "$(field 2)" "phase without an index"
session cook-no-index active beef-stew collagen-conversion "banana" "null"
run
expect_eq "Collagen Conversion" "$(field 2)" "phase with a non-integer index"
session cook-no-index active beef-stew collagen-conversion "-4" "null"
run
expect_eq "Collagen Conversion" "$(field 2)" "phase with a negative index"
session cook-no-index active beef-stew collagen-conversion "4000" "null"
run
expect_eq "Collagen Conversion" "$(field 2)" "phase with an absurd index"
end

begin "an absent current_phase drops the phase slot"
user_statusline 'echo USER-LINE'
session_file cook-no-phase <<EOF
---
protocol: beef-stew
phase_index: 3
phase_end: null
status: active
---
EOF
run
expect_eq 2 "$(field_count)" "field count"
expect_eq "🍲 Beef Stew" "$(field 1)" "dish"
expect_clock 2
end

begin "a name made only of separators is not a dish"
user_statusline 'echo USER-LINE'
session cook-empty-name active "\"---\"" collagen-conversion 3 "null"
run
expect_eq "USER-LINE" "$LINE" "line when protocol titleizes to nothing"
session cook-empty-name active beef-stew "\"-\"" 3 "null"
run
expect_eq 2 "$(field_count)" "field count when current_phase titleizes to nothing"
expect_eq "🍲 Beef Stew" "$(field 1)" "dish"
end

begin "malformed state files are treated as not active"
sessions_dir
user_statusline 'echo USER-LINE'
# No front matter at all.
printf '# just a markdown file\n\nstatus: active\n' > "$PROJECT/sessions/cook-a-no-frontmatter.md"
# Front matter that never closes.
printf -- '---\nprotocol: broken\nstatus: active\ncurrent_phase: x\nphase_index: 1\n' \
    > "$PROJECT/sessions/cook-b-unterminated.md"
# A phase_end that will not parse — a wrong countdown is worse than none.
session cook-c-bad-deadline active beef-stew braise 3 '"tuesday-ish"'
# A dangling symlink: stat() fails, the candidate is skipped.
ln -s "$PROJECT/sessions/nope.md" "$PROJECT/sessions/cook-d-dangling.md"
run
expect_eq "USER-LINE" "$LINE" "line when every active file is malformed"
expect_contains "$(cat "$ERR")" "never closed" "unterminated front matter noted on stderr"
end

begin "a malformed newest session does not hide a good older one"
session cook-2026-07-29-beef-stew active beef-stew collagen-conversion 3 "\"$(iso_offset 1410)\""
session cook-2026-07-30-broken active beef-stew braise 3 '"tuesday-ish"'
touch "$PROJECT/sessions/cook-2026-07-30-broken.md"
user_statusline 'echo USER-LINE'
run
expect_eq "🍲 Beef Stew" "$(field 1)" "dish from the older, valid session"
expect_eq "23min left" "$(field 4)" "timer from the older, valid session"
end

begin "a pathological sessions/ directory is bounded during enumeration"
sessions_dir
user_statusline 'echo USER-LINE'
python3 -c 'import sys
from pathlib import Path
target = Path(sys.argv[1])
for n in range(260):
    (target / ("cook-filler-%03d.md" % n)).write_text("---\nprotocol: filler\nstatus: completed\n---\n")' \
    "$PROJECT/sessions"
run
expect_contains "$(cat "$ERR")" "session files" "cap engaged before every file was stat()ed"
end

begin "a nested status: key cannot fake an active cook"
sessions_dir
user_statusline 'echo USER-LINE'
cat > "$PROJECT/sessions/cook-nested.md" <<'EOF'
---
protocol: beef-stew
current_phase: braise
phase_index: 3
phase_end: null
last_sensor:
  status: active
status: completed
---
EOF
run
expect_eq "USER-LINE" "$LINE" "line with only a nested active marker"
end

begin "no chainable statusline falls back to dir and model"
sessions_dir
printf '{"model": "opus"}\n' > "$HOME_DIR/.claude/settings.json"
run
expect_eq "project | Fable 5" "$LINE" "fallback line"
end

begin "a chain that produces nothing falls back"
sessions_dir
user_statusline 'exit 3'
run
expect_eq "project | Fable 5" "$LINE" "fallback line"
end

begin "a chain that hangs is abandoned, and takes its children with it"
sessions_dir
# A grandchild, not the shell itself: killing only the shell leaks one of these
# per refresh, and refreshInterval is 1.
user_statusline "python3 -c 'import time; time.sleep(30)' $HANG_MARKER"
started=$(date +%s)
run
elapsed=$(( $(date +%s) - started ))
expect_eq "project | Fable 5" "$LINE" "fallback line"
if [ "$elapsed" -gt 5 ]; then
    problem "chain timeout: took ${elapsed}s, expected the 2s cap"
fi
if pgrep -f "$HANG_MARKER" >/dev/null 2>&1; then
    problem "the hung chain's child outlived the timeout"
    pkill -f "$HANG_MARKER" >/dev/null 2>&1
fi
end

begin "a globally-installed copy does not recurse"
sessions_dir
# The stub records every invocation: without the guard the script chains to
# itself, and the count — not the elapsed time — is what shows it.
user_statusline "echo invoked >> '$COUNTER'
exec python3 '$SCRIPT'"
invocations=0
attempt=0
# Zero invocations is not a guard failure: on a loaded machine the stub can
# still be starting when the script's 2s cap fires. Only a count above one
# means the guard is gone, so retry a zero rather than report it.
while [ "$attempt" -lt 3 ]; do
    attempt=$((attempt + 1))
    : > "$COUNTER"
    started=$(date +%s)
    run
    elapsed=$(( $(date +%s) - started ))
    invocations="$(awk 'END {print NR}' "$COUNTER")"
    [ "$invocations" = "0" ] || break
done
expect_eq "project | Fable 5" "$LINE" "fallback line from the guarded child"
expect_eq 1 "$invocations" "chained command invocations"
if [ "$elapsed" -gt 5 ]; then
    problem "recursion guard: took ${elapsed}s"
fi
end

begin "garbage on stdin is not a crash"
sessions_dir
user_statusline 'echo USER-LINE'
# No payload means no project_dir, so the script falls back to its own cwd —
# run these from the scratch dir, or the row asserts on whatever cook happens
# to be live in the directory the suite was launched from.
(cd "$WORK" && printf 'not json at all' | HOME="$HOME_DIR" python3 "$SCRIPT") >"$OUT" 2>"$ERR"
expect_eq 0 "$?" "exit status"
[ -s "$OUT" ] || problem "stdout was empty"
expect_eq "USER-LINE" "$(head -1 "$OUT")" "chained line"
: > "$OUT"
(cd "$WORK" && printf '' | HOME="$HOME_DIR" python3 "$SCRIPT") >"$OUT" 2>"$ERR"
expect_eq 0 "$?" "exit status with empty stdin"
expect_eq "USER-LINE" "$(head -1 "$OUT")" "chained line with empty stdin"
end

begin "an unexpected exception still reaches the chain, prints a line and exits 0"
session cook-2026-07-30-beef-stew active beef-stew collagen-conversion 3 "\"$(iso_offset 1410)\""
user_statusline 'echo USER-LINE'
mkdir -p "$WORK/crashy"
python3 - "$SCRIPT_SRC" "$WORK/crashy/cook-statusline.py" <<'PY'
import sys
source, destination = sys.argv[1], sys.argv[2]
text = open(source, encoding="utf-8").read()
needle = "def active_banner(payload, now):\n"
if needle not in text:
    sys.exit("fault injection point moved — update the test")
open(destination, "w", encoding="utf-8").write(
    text.replace(needle, needle + '    raise RuntimeError("injected fault")\n', 1))
PY
expect_eq 0 "$?" "fault injection"
run "$WORK/crashy/cook-statusline.py"
expect_eq "USER-LINE" "$LINE" "chained line after a crash in the session scan"
expect_contains "$(cat "$ERR")" "injected fault" "crash noted on stderr"
# And with nothing to chain to, the plain line is still there.
printf '{"model": "opus"}\n' > "$HOME_DIR/.claude/settings.json"
run "$WORK/crashy/cook-statusline.py"
expect_eq "project | Fable 5" "$LINE" "fallback line after a crash with no chain"
rm -rf "$WORK/crashy"
end

begin "the command the help skill installs works from a path with a space"
session cook-2026-07-30-beef-stew active beef-stew collagen-conversion 3 "\"$(iso_offset 1410)\""
spaced="$WORK/pan out/skills/panout-cook/bin"
mkdir -p "$spaced" "$PROJECT/.claude"
cp "$SCRIPT_SRC" "$spaced/cook-statusline.py"
# The exact JSON the help skill's snippet writes, quoted the way it quotes it.
cat > "$PROJECT/.claude/settings.json" <<EOF
{"enabledPlugins": {"pan-out": true},
 "statusLine": {"type": "command",
                "command": "python3 '$spaced/cook-statusline.py'",
                "refreshInterval": 1}}
EOF
installed="$(python3 -c 'import json, sys
print(json.load(open(sys.argv[1]))["statusLine"]["command"])' "$PROJECT/.claude/settings.json")"
CLOCK_BEFORE="$(date +%H:%M)"
payload "$PROJECT" "$PROJECT" | HOME="$HOME_DIR" sh -c "$installed" >"$OUT" 2>"$ERR"
expect_eq 0 "$?" "exit status of the installed command"
CLOCK_AFTER="$(date +%H:%M)"
LINE="$(head -1 "$OUT")"
expect_eq "🍲 Beef Stew" "$(field 1)" "dish"
expect_eq "PHASE 3: Collagen Conversion" "$(field 2)" "phase"
expect_eq "23min left" "$(field 4)" "timer"
end

begin "a rendered banner costs well under 100ms"
session cook-2026-07-30-beef-stew active beef-stew collagen-conversion 3 "\"$(iso_offset 1410)\""
median=$(HOME="$HOME_DIR" python3 - "$SCRIPT" "$PROJECT" <<'PY'
import json, subprocess, sys, time
script, project = sys.argv[1], sys.argv[2]
payload = json.dumps({
    "cwd": project,
    "model": {"display_name": "Fable 5"},
    "workspace": {"project_dir": project},
}).encode()
samples = []
for _ in range(5):
    start = time.perf_counter()
    done = subprocess.run([sys.executable, script], input=payload,
                          stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    samples.append((time.perf_counter() - start) * 1000)
    if done.returncode != 0:
        print("exit status %d" % done.returncode)
        raise SystemExit(0)
    if not done.stdout.strip():
        print("no output")
        raise SystemExit(0)
# The median: one scheduling hiccup on a loaded machine is not a regression.
print(int(sorted(samples)[len(samples) // 2]))
PY
)
case "$median" in
    ''|*[!0-9]*) problem "timing run failed: $median" ;;
    *) [ "$median" -lt 100 ] || problem "median render took ${median}ms, budget is 100ms" ;;
esac
end

# --- summary ----------------------------------------------------------------

echo
printf '%d passed, %d failed\n' "$PASSED" "$FAILED"
if [ "$FAILED" -gt 0 ]; then
    printf 'failures:%s\n' "$FAILED_ROWS"
    exit 1
fi
exit 0
