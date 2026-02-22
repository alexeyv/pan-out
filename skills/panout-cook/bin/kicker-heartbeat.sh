#!/bin/bash
# Called in a LOOP by the kicker agent — not a one-shot script.
# Each invocation: sleep precisely until the next event is due (capped at 60s),
# output FIRE lines for all due events, prune schedule, exit.
# The kicker agent parses output and calls this script again for the next batch.
# When schedule is empty: output DONE and exit.

SCHEDULE_FILE="$1"
if [ ! -f "$SCHEDULE_FILE" ]; then
    echo "ERROR:no_schedule:Schedule file not found: $SCHEDULE_FILE"
    exit 1
fi

if [ ! -s "$SCHEDULE_FILE" ]; then
    echo "DONE"
    exit 0
fi

# Compute sleep duration: time until next event, capped at 60s
NOW=$(date +%s)
NEXT_TS=$(sort -n "$SCHEDULE_FILE" | head -1 | cut -f1)

if [ -z "$NEXT_TS" ]; then
    echo "DONE"
    exit 0
fi

GAP=$(( NEXT_TS - NOW ))
if [ "$GAP" -gt 0 ]; then
    SLEEP_SECS=$(( GAP < 60 ? GAP : 60 ))
    sleep "$SLEEP_SECS"
fi
# If GAP <= 0, the event is already due — fire immediately

NOW=$(date +%s)
FIRED=""

while IFS=$'\t' read -r ts task_id msg; do
    if [ "$NOW" -ge "$ts" ]; then
        echo "FIRE:${task_id}:${msg}"
        FIRED="yes"
    fi
done < "$SCHEDULE_FILE"

if [ -n "$FIRED" ]; then
    TEMP=$(mktemp) || { echo "ERROR:mktemp_failed:Cannot create temp file for schedule prune"; exit 1; }
    while IFS=$'\t' read -r ts task_id msg; do
        if [ "$NOW" -lt "$ts" ]; then
            printf '%s\t%s\t%s\n' "$ts" "$task_id" "$msg" >> "$TEMP"
        fi
    done < "$SCHEDULE_FILE"
    mv "$TEMP" "$SCHEDULE_FILE"
    exit 0
fi

# No events fired this tick (possible if multiple iterations of the cap-at-60s path)
if [ ! -s "$SCHEDULE_FILE" ]; then
    echo "DONE"
    exit 0
fi
