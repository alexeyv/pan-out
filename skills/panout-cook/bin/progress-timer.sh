#!/bin/bash

# Progress timer that speaks updates every minute and logs to file
# Usage: progress-timer.sh <TOTAL_SECONDS> <LABEL>
#
# Sleeps to wall-clock boundaries so TTS/sound overhead never causes drift.
# If TTS takes longer than a full minute, the overdue tick is skipped.

TOTAL_SECONDS=$1
LABEL=$2
LOG_FILE="/tmp/braise_timer.log"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Wall-clock anchor — all ticks are relative to this
START_EPOCH=$(date +%s)

# Initialize log
echo "Timer started: $(date)" > "$LOG_FILE"
echo "Total duration: $TOTAL_SECONDS seconds" >> "$LOG_FILE"

# Pluralize helper: "1 minute" vs "3 minutes"
plural() {
    local n=$1 word=$2
    if [ "$n" -eq 1 ]; then echo "$n $word"; else echo "$n ${word}s"; fi
}

NEXT_TICK=60  # first announcement at 1 minute — the cook agent announces the start

while [ $NEXT_TICK -lt $TOTAL_SECONDS ]; do
    # How long until this tick's wall-clock moment?
    TARGET_EPOCH=$((START_EPOCH + NEXT_TICK))
    NOW_EPOCH=$(date +%s)
    SLEEP_FOR=$((TARGET_EPOCH - NOW_EPOCH))

    if [ $SLEEP_FOR -gt 0 ]; then
        sleep $SLEEP_FOR
    fi

    # Re-check wall clock — did we overshoot into the NEXT tick?
    NOW_EPOCH=$(date +%s)
    ACTUAL_ELAPSED=$((NOW_EPOCH - START_EPOCH))

    if [ $ACTUAL_ELAPSED -ge $TOTAL_SECONDS ]; then
        # Timer is done, skip to completion
        break
    fi

    # If we're more than 55 seconds past this tick, skip it (TTS took too long)
    if [ $((ACTUAL_ELAPSED - NEXT_TICK)) -gt 55 ]; then
        echo "$(date '+%H:%M:%S') - [skipped tick at ${NEXT_TICK}s — TTS overran]" >> "$LOG_FILE"
        NEXT_TICK=$((NEXT_TICK + 60))
        continue
    fi

    REMAINING=$((TOTAL_SECONDS - NEXT_TICK))
    REMAINING_MIN=$((REMAINING / 60))
    REMAINING_SEC=$((REMAINING % 60))
    ELAPSED_MIN=$((NEXT_TICK / 60))

    # Soft tick sound
    "$SCRIPT_DIR/chime.sh" tick

    # Build message with correct plurals
    if [ $REMAINING_SEC -eq 0 ]; then
        MESSAGE="${LABEL}: $(plural $ELAPSED_MIN minute) elapsed, $(plural $REMAINING_MIN minute) remaining"
    else
        MESSAGE="${LABEL}: $(plural $ELAPSED_MIN minute) elapsed, $(plural $REMAINING_MIN minute) $(plural $REMAINING_SEC second) remaining"
    fi

    "$SCRIPT_DIR/speak.sh" "$MESSAGE"

    echo "$(date '+%H:%M:%S') - $MESSAGE - Elapsed: $NEXT_TICK seconds" >> "$LOG_FILE"

    NEXT_TICK=$((NEXT_TICK + 60))
done

# Sleep until the actual end time (in case we broke out of the loop early)
END_EPOCH=$((START_EPOCH + TOTAL_SECONDS))
NOW_EPOCH=$(date +%s)
SLEEP_FOR=$((END_EPOCH - NOW_EPOCH))
if [ $SLEEP_FOR -gt 0 ]; then
    sleep $SLEEP_FOR
fi

# Completion: play a loud, distinctive alarm that can't be missed
COMPLETE_MSG="${LABEL}: Complete!"

"$SCRIPT_DIR/chime.sh" alarm

"$SCRIPT_DIR/speak.sh" "$COMPLETE_MSG"
sleep 2
# Repeat the announcement in case the cook was away
"$SCRIPT_DIR/speak.sh" "$COMPLETE_MSG"

echo "$(date '+%H:%M:%S') - $COMPLETE_MSG" >> "$LOG_FILE"
