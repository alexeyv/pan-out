#!/bin/bash

# Start the background photo receiver for push-mode photo capture.
# Usage: start-photo-receiver.sh <inbox_dir> [port]
#
# Prints the laptop's local IP so you can configure the Android shortcut.
# Writes PID to /tmp/panout-photo-receiver.pid for later cleanup.

INBOX_DIR="$1"
PORT="${2:-8765}"

if [ -z "$INBOX_DIR" ]; then
    echo "Usage: start-photo-receiver.sh <inbox_dir> [port]"
    exit 1
fi

# Get local WiFi IP (macOS first, then Linux)
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null \
    || ipconfig getifaddr en1 2>/dev/null \
    || hostname -I 2>/dev/null | awk '{print $1}')

# Start receiver in background, capturing its output
python3 "$(dirname "$0")/photo-receiver.py" "$INBOX_DIR" "$PORT" &
RECEIVER_PID=$!
echo "$RECEIVER_PID" > /tmp/panout-photo-receiver.pid

# Wait for startup confirmation
sleep 0.5

echo "Photo receiver started (PID $RECEIVER_PID)"
echo "POST endpoint: http://${LOCAL_IP}:${PORT}/photo"
echo "Inbox: $INBOX_DIR"
