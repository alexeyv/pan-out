#!/bin/bash

# Cross-platform alert sound wrapper
# Usage: chime.sh [tick|alert|alarm]
# Plays platform-appropriate sounds at different urgency levels.

LEVEL="${1:-alert}"

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
SOUNDS="/System/Library/Sounds"

play_macos() {
    case "$LEVEL" in
        tick)
            afplay "$SOUNDS/Tink.aiff"
            ;;
        alert)
            afplay "$SOUNDS/Glass.aiff"
            ;;
        alarm)
            for i in 1 2 3; do
                afplay "$SOUNDS/Glass.aiff"
                sleep 0.3
                afplay "$SOUNDS/Hero.aiff"
                sleep 0.3
                afplay "$SOUNDS/Funk.aiff"
                sleep 0.5
            done
            ;;
    esac
}

play_wsl() {
    # Resolve powershell.exe — may not be on PATH in all WSL contexts
    local PS
    PS=$(command -v powershell.exe 2>/dev/null) \
        || PS="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
    [ -x "$PS" ] || return 0

    case "$LEVEL" in
        tick)
            "$PS" -NoProfile -c "[Console]::Beep(800, 150)" 2>/dev/null
            ;;
        alert)
            "$PS" -NoProfile -c "[Console]::Beep(600, 300); Start-Sleep -Milliseconds 150; [Console]::Beep(600, 300)" 2>/dev/null
            ;;
        alarm)
            "$PS" -NoProfile -c "for (\`\$r = 0; \`\$r -lt 3; \`\$r++) { [Console]::Beep(600, 200); [Console]::Beep(800, 200); [Console]::Beep(1000, 300); Start-Sleep -Milliseconds 400 }" 2>/dev/null
            ;;
    esac
}

play_linux() {
    # Try paplay with system sounds, else silent
    if command -v paplay &>/dev/null; then
        SOUND_DIR="/usr/share/sounds/freedesktop/stereo"
        case "$LEVEL" in
            tick)
                [ -f "$SOUND_DIR/message.oga" ] && paplay "$SOUND_DIR/message.oga"
                ;;
            alert)
                [ -f "$SOUND_DIR/bell.oga" ] && paplay "$SOUND_DIR/bell.oga"
                ;;
            alarm)
                for i in 1 2 3; do
                    [ -f "$SOUND_DIR/alarm-clock-elapsed.oga" ] && paplay "$SOUND_DIR/alarm-clock-elapsed.oga"
                    sleep 0.5
                done
                ;;
        esac
    fi
    # No paplay or no sound files — silent no-op
}

case "$PLATFORM" in
    macos)  play_macos ;;
    wsl)    play_wsl ;;
    linux)  play_linux ;;
esac

exit 0
