#!/usr/bin/env python3
"""poll-adapter.py — bridge between events.jsonl and the cook agent.

The cook agent runs this with run_in_background: true. It checks
events.jsonl for new complete lines since the last read, outputs them
to stdout, updates the byte offset, and exits. The cook agent parses
stdout and re-invokes. No timer logic — just file-to-stdout plumbing.

Usage: python3 poll-adapter.py <session-dir>

Reads:  <session-dir>/events.jsonl
State:  <session-dir>/.offset  (byte offset into events.jsonl)
"""

import os
import sys
import time

POLL_SLEEP = int(os.environ.get("POLL_SLEEP", 5))


def read_offset(offset_path):
    """Read the stored byte offset, or 0 if no offset file exists."""
    try:
        with open(offset_path, "r") as f:
            raw = f.read().strip()
        return int(raw)
    except FileNotFoundError:
        return 0
    except ValueError:
        print(f"ERROR: Corrupt offset file: {offset_path}", file=sys.stderr)
        sys.exit(1)


def save_offset(offset_path, offset):
    """Atomically write the byte offset (temp + rename)."""
    tmp = offset_path + ".tmp"
    with open(tmp, "w") as f:
        f.write(str(offset))
    os.replace(tmp, offset_path)


def poll_once(events_path, offset):
    """Read new complete lines from events_path starting at byte offset.

    Returns (lines_bytes, new_offset) where lines_bytes is the raw bytes
    of all complete lines to emit, and new_offset is the updated position.
    Returns (b"", offset) if there's nothing new.
    """
    try:
        with open(events_path, "rb") as f:
            file_size = f.seek(0, 2)
            if file_size < offset:
                # Offset past EOF — file was recreated, reset to start
                print("WARN: offset past EOF, resetting to 0", file=sys.stderr)
                offset = 0
            f.seek(offset)
            chunk = f.read()
    except OSError:
        return b"", offset

    if not chunk:
        return b"", offset

    # Find the last newline — everything up to and including it is complete.
    last_nl = chunk.rfind(b"\n")
    if last_nl == -1:
        return b"", offset

    complete = chunk[: last_nl + 1]
    return complete, offset + len(complete)


def main():
    if sys.platform == "win32":
        import msvcrt
        msvcrt.setmode(sys.stdout.fileno(), os.O_BINARY)

    if len(sys.argv) != 2:
        print("Usage: python3 poll-adapter.py <session-dir>", file=sys.stderr)
        sys.exit(1)

    session_dir = sys.argv[1]
    if not os.path.isdir(session_dir):
        print(f"ERROR: Session directory does not exist: {session_dir}", file=sys.stderr)
        sys.exit(1)

    events_path = os.path.join(session_dir, "events.jsonl")
    offset_path = os.path.join(session_dir, ".offset")

    offset = read_offset(offset_path)

    # First check — return immediately if events are waiting
    data, new_offset = poll_once(events_path, offset)
    if data:
        sys.stdout.buffer.write(data)
        sys.stdout.buffer.flush()
        save_offset(offset_path, new_offset)
        return

    # No new events — sleep once and re-check before exiting
    time.sleep(POLL_SLEEP)

    data, new_offset = poll_once(events_path, offset)
    if data:
        sys.stdout.buffer.write(data)
        sys.stdout.buffer.flush()
        save_offset(offset_path, new_offset)


if __name__ == "__main__":
    main()
