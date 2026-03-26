#!/usr/bin/env python3
"""kicker.py — reference kicker implementation for the Pan Out cook skill.

Reads schedule.json from a session directory, fires events to events.jsonl
on schedule, polls control.jsonl for shutdown/extend commands, and exits
after writing a done or error event.

Usage: python3 kicker.py <session-dir>

Conforms to kicker-protocol.md v1. Stdlib only — no third-party imports.
"""

import json
import os
import sys
import time


def log(msg):
    """Write diagnostic message to stderr."""
    print(f"kicker: {msg}", file=sys.stderr, flush=True)


def now_epoch():
    return int(time.time())


# ---------------------------------------------------------------------------
# Atomic I/O
# ---------------------------------------------------------------------------

def append_jsonl(path, obj):
    """Atomically append a JSON line to a JSONL file using O_APPEND.

    POSIX guarantees atomicity for O_APPEND writes under 4096 bytes.
    """
    line = json.dumps(obj, separators=(",", ":")) + "\n"
    data = line.encode("utf-8")
    fd = os.open(path, os.O_WRONLY | os.O_APPEND | os.O_CREAT, 0o644)
    try:
        os.write(fd, data)
    finally:
        os.close(fd)


def read_complete_lines(path, offset):
    """Read complete lines from a file starting at byte offset.

    Returns (lines, new_offset). Ignores any trailing partial line.
    """
    try:
        with open(path, "rb") as f:
            f.seek(0, 2)
            size = f.tell()
            if size < offset:
                offset = 0
            f.seek(offset)
            chunk = f.read()
    except OSError:
        return [], offset

    if not chunk:
        return [], offset

    last_nl = chunk.rfind(b"\n")
    if last_nl == -1:
        return [], offset

    complete = chunk[: last_nl + 1]
    lines = complete.decode("utf-8").splitlines()
    return lines, offset + len(complete)


# ---------------------------------------------------------------------------
# Schedule loading
# ---------------------------------------------------------------------------

def load_schedule(session_dir):
    """Load and validate schedule.json. Returns event list or raises."""
    path = os.path.join(session_dir, "schedule.json")
    with open(path, "r") as f:
        data = json.load(f)

    if data.get("version") != 1:
        raise ValueError(f"unsupported schedule version: {data.get('version')}")

    events = data.get("events", [])
    for e in events:
        for field in ("id", "type", "epoch", "message"):
            if field not in e:
                raise ValueError(f"event missing required field '{field}': {e}")

    return sorted(events, key=lambda e: e["epoch"])


# ---------------------------------------------------------------------------
# Control processing
# ---------------------------------------------------------------------------

def process_control(session_dir, control_offset, events):
    """Read new control commands and apply them.

    Returns (new_offset, should_shutdown).
    """
    control_path = os.path.join(session_dir, "control.jsonl")
    lines, new_offset = read_complete_lines(control_path, control_offset)

    for line in lines:
        line = line.strip()
        if not line:
            continue
        try:
            cmd = json.loads(line)
        except json.JSONDecodeError:
            log(f"ignoring malformed control line: {line}")
            continue

        cmd_type = cmd.get("type")

        if cmd_type == "shutdown":
            log("received shutdown command")
            return new_offset, True

        if cmd_type == "extend":
            seconds = cmd.get("seconds", 0)
            if not isinstance(seconds, (int, float)):
                log(f"ignoring extend with non-numeric seconds: {seconds}")
                continue
            apply_extend(events, int(seconds))

    return new_offset, False


def apply_extend(events, seconds):
    """Shift all unfired events by `seconds`. Clamp to now+5 if negative."""
    if seconds == 0:
        return
    log(f"extending unfired events by {seconds}s")
    ts = now_epoch()
    for e in events:
        if e.get("_fired"):
            continue
        e["epoch"] += seconds
        if e["epoch"] < ts + 5:
            e["epoch"] = ts + 5


# ---------------------------------------------------------------------------
# Event firing
# ---------------------------------------------------------------------------

def fire_event(session_dir, event):
    """Write a fire line to events.jsonl for the given event."""
    obj = {
        "type": "fire",
        "event_id": event["id"],
        "message": event["message"],
        "ts": now_epoch(),
    }
    if "detail" in event:
        obj["detail"] = event["detail"]

    events_path = os.path.join(session_dir, "events.jsonl")
    append_jsonl(events_path, obj)
    log(f"fired: {event['id']} ({event['type']})")


def write_done(session_dir, reason):
    """Write a done event to events.jsonl."""
    events_path = os.path.join(session_dir, "events.jsonl")
    append_jsonl(events_path, {"type": "done", "reason": reason, "ts": now_epoch()})
    log(f"done: {reason}")


def write_error(session_dir, message):
    """Write an error event to events.jsonl."""
    events_path = os.path.join(session_dir, "events.jsonl")
    append_jsonl(events_path, {"type": "error", "message": message, "ts": now_epoch()})
    log(f"error: {message}")


# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 kicker.py <session-dir>", file=sys.stderr)
        sys.exit(1)

    session_dir = sys.argv[1]

    # Load schedule
    try:
        events = load_schedule(session_dir)
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        # Create events.jsonl so poll adapter can read the error
        try:
            write_error(session_dir, f"schedule load failed: {exc}")
        except OSError:
            log(f"FATAL: cannot write error event: {exc}")
        sys.exit(1)

    # Create empty events.jsonl before entering main loop
    events_path = os.path.join(session_dir, "events.jsonl")
    if not os.path.exists(events_path):
        fd = os.open(events_path, os.O_WRONLY | os.O_CREAT, 0o644)
        os.close(fd)

    log(f"loaded {len(events)} events")

    # Empty schedule — done immediately
    if not events:
        write_done(session_dir, "schedule_complete")
        return

    control_offset = 0
    fired_count = 0
    total = len(events)

    try:
        while fired_count < total:
            # Check control commands
            control_offset, shutdown = process_control(
                session_dir, control_offset, events
            )
            if shutdown:
                write_done(session_dir, "shutdown")
                return

            # Fire any due events
            ts = now_epoch()
            for e in events:
                if e.get("_fired"):
                    continue
                if ts >= e["epoch"]:
                    fire_event(session_dir, e)
                    e["_fired"] = True
                    fired_count += 1

            if fired_count >= total:
                break

            # Sleep: min(time to next unfired event, 5s) for control responsiveness
            next_epoch = min(e["epoch"] for e in events if not e.get("_fired"))
            sleep_time = max(0, min(next_epoch - now_epoch(), 5))
            if sleep_time > 0:
                time.sleep(sleep_time)
    except Exception as exc:
        log(f"unexpected error: {exc}")
        try:
            write_error(session_dir, f"kicker crashed: {exc}")
        except OSError:
            log(f"FATAL: cannot write error event")
        sys.exit(1)

    write_done(session_dir, "schedule_complete")


if __name__ == "__main__":
    main()
