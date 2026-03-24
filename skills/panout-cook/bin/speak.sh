#!/bin/bash

# Cross-platform TTS wrapper
# Usage: speak.sh "message to speak"
# Detects platform and calls the appropriate TTS command.

MESSAGE="$1"
[ -z "$MESSAGE" ] && exit 0

detect_platform() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "macos"
    elif [[ "$(uname)" == "Linux" ]] && grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
    else
        echo "linux"
    fi
}

PLATFORM=$(detect_platform)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Play attention chime concurrently with TTS — the chime grabs attention
# during the synthesis delay so there's no dead air. Backgrounding avoids
# afplay's blocking tail silence on macOS.
case "$PLATFORM" in
    macos)
        afplay /System/Library/Sounds/Glass.aiff &
        command -v say &>/dev/null && say "$MESSAGE"
        wait
        ;;
    wsl)
        # WSL: chime then speak (no backgrounding needed — Console::Beep is fast)
        "$SCRIPT_DIR/chime.sh" alert 2>/dev/null
        command -v wsay &>/dev/null && wsay "$MESSAGE"
        ;;
    linux)
        "$SCRIPT_DIR/chime.sh" alert 2>/dev/null &
        if command -v espeak >/dev/null 2>&1; then
            espeak -s 150 -v en-us "$MESSAGE"
        else
            echo "TTS unavailable (install espeak): $MESSAGE" >&2
        fi
        wait
        ;;
esac

exit 0
