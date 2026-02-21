#!/bin/bash
# Called in a LOOP by the kicker agent — not a one-shot script.
# Each invocation: sleep in 60s ticks until one or more events are due,
# output FIRE lines, prune schedule, exit. The kicker agent parses output
# and calls this script again for the next batch.
# When schedule is empty: output DONE and exit.

# Kicker heartbeat — polls schedule every 60s, exits when event(s) fire
# Usage: kicker-heartbeat.sh /path/to/schedule.tsv
# Schedule format: epoch_timestamp\ttask_id\tmessage (one per line)
# Output on fire: "FIRE:task_id:message" (one per fired event)
# Output when empty: "DONE"

SCHEDULE_FILE="$1"
if [ ! -f "$SCHEDULE_FILE" ]; then
    echo "ERROR:no_schedule:Schedule file not found: $SCHEDULE_FILE"
    exit 1
fi

if [ ! -s "$SCHEDULE_FILE" ]; then
    echo "DONE"
    exit 0
fi

while true; do
    sleep 60
    NOW=$(date +%s)
    FIRED=""

    # Check each entry
    while IFS=$'\t' read -r ts task_id msg; do
        if [ "$NOW" -ge "$ts" ]; then
            echo "FIRE:${task_id}:${msg}"
            FIRED="yes"
        fi
    done < "$SCHEDULE_FILE"

    if [ -n "$FIRED" ]; then
        # Remove fired entries, keep future ones
        TEMP=$(mktemp)
        while IFS=$'\t' read -r ts task_id msg; do
            if [ "$NOW" -lt "$ts" ]; then
                printf '%s\t%s\t%s\n' "$ts" "$task_id" "$msg" >> "$TEMP"
            fi
        done < "$SCHEDULE_FILE"
        mv "$TEMP" "$SCHEDULE_FILE"
        exit 0
    fi

    # Empty schedule = all done
    if [ ! -s "$SCHEDULE_FILE" ]; then
        echo "DONE"
        exit 0
    fi
done
