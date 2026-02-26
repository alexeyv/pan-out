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

case "$PLATFORM" in
    macos)
        command -v say &>/dev/null && say "$MESSAGE"
        ;;
    wsl)
        command -v wsay &>/dev/null && wsay "$MESSAGE"
        ;;
    linux)
        if command -v espeak >/dev/null 2>&1; then
            espeak -s 150 -v en-us "$MESSAGE"
        else
            echo "TTS unavailable (install espeak): $MESSAGE" >&2
        fi
        ;;
esac

exit 0
