#!/bin/bash

# Capture a photo from an IP Webcam Android app
# Usage: capture-photo.sh <camera_url> <output_path> [label]
#
# Called by the panout-capture-photo skill, which handles URL discovery
# and caching in the session state file.
#
# Exit codes:
#   0 — success, photo saved
#   1 — missing arguments
#   3 — camera unreachable
#   4 — capture failed

CAMERA_URL="$1"
OUTPUT_PATH="$2"
LABEL="${3:-photo}"

if [ -z "$CAMERA_URL" ] || [ -z "$OUTPUT_PATH" ]; then
    echo "Usage: capture-photo.sh <camera_url> <output_path> [label]"
    exit 1
fi

# Strip trailing slash
CAMERA_URL="${CAMERA_URL%/}"

# Check if camera is reachable (1 second timeout)
if ! curl -s --connect-timeout 1 --max-time 2 "$CAMERA_URL/status.json" > /dev/null 2>&1; then
    echo "ERROR: Camera not reachable at $CAMERA_URL"
    echo "Is IP Webcam running on the phone?"
    exit 3
fi

# Ensure output directory exists
mkdir -p "$(dirname "$OUTPUT_PATH")"

# Capture with autofocus (photoaf.jpg triggers AF then captures)
HTTP_CODE=$(curl -s -w "%{http_code}" --max-time 10 -o "$OUTPUT_PATH" "$CAMERA_URL/photoaf.jpg")

if [ "$HTTP_CODE" != "200" ] || [ ! -s "$OUTPUT_PATH" ]; then
    echo "ERROR: Capture failed (HTTP $HTTP_CODE)"
    rm -f "$OUTPUT_PATH"
    exit 4
fi

# Report success
FILE_SIZE=$(stat -f%z "$OUTPUT_PATH" 2>/dev/null || stat -c%s "$OUTPUT_PATH" 2>/dev/null)
echo "Captured: $OUTPUT_PATH ($FILE_SIZE bytes) — $LABEL"
exit 0
