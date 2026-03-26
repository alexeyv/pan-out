# Kicker Protocol v1

A communication protocol between a **cook agent** (Claude Code session managing a cook) and a **kicker process** (any external timer that fires events on schedule).

The protocol is two JSONL streams — one in each direction — plus a one-shot JSON schedule. The message types, lifecycle, and semantics are transport-independent: the same messages work over files, Unix sockets, stdin/stdout pipes, WebSocket, or HTTP.

The default transport is files, because a Claude Code agent has filesystem tools and a bash tool and nothing else. Files also give you an audit log for free. But nothing in the message format requires files — a server-based kicker would speak the same JSONL over a socket.

All data is UTF-8 encoded.

## Transport: Files

When using file transport, all protocol files live in a single session directory:

```text
/tmp/kicker-{session}/
├── schedule.json     # Cook agent writes, kicker reads
├── events.jsonl      # Kicker writes (append-only), cook agent reads
└── control.jsonl     # Cook agent writes (append-only), kicker reads
```

`{session}` is an opaque string chosen by the cook agent (typically the cook session ID). The cook agent creates the directory before starting the kicker.

## schedule.json

Written by the cook agent before starting the kicker. The kicker reads it once at startup and loads events into memory.

```json
{
  "version": 1,
  "created": 1771686000,
  "events": [
    {
      "id": "progress-1",
      "type": "progress",
      "epoch": 1771686600,
      "message": "10 min elapsed — bath holding at 63°C",
      "detail": "Progress check for Phase 2 Sous Vide Bath. 28 min remaining. Check bag seal and bath level."
    },
    {
      "id": "preflight-sear",
      "type": "preflight",
      "epoch": 1771687200,
      "message": "Pre-flight briefing for sear phase",
      "detail": "Phase 3 Cast Iron Sear begins in 15 min. Equipment needed: cast iron skillet, high-smoke-point oil, tongs. Pat dry the protein, season exterior. Preheat skillet to smoking."
    },
    {
      "id": "ready-check-sear",
      "type": "ready-check",
      "epoch": 1771687800,
      "message": "Ready check — cook staged for sear?",
      "detail": "Sear phase begins in 5 min. Confirm: protein patted dry, skillet at smoking temp, oil ready, exhaust fan on. Acknowledge or request extension."
    },
    {
      "id": "countdown-4",
      "type": "countdown",
      "epoch": 1771688040,
      "message": "4 min to sear phase"
    },
    {
      "id": "complete-bath",
      "type": "complete",
      "epoch": 1771688280,
      "message": "Timer complete — begin Phase 3 Cast Iron Sear",
      "detail": "Sous vide hold finished. Remove bag from bath, pat protein dry immediately. Proceed to sear."
    }
  ]
}
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | integer | yes | Protocol version. Always `1` for this spec. |
| `created` | integer | yes | Unix epoch when schedule was generated. |
| `events` | array | yes | List of event objects, sorted by `epoch` ascending. May be empty (zero events). |

### Event object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | Unique within this schedule. Used to correlate fire events. |
| `type` | string | yes | One of: `progress`, `preflight`, `ready-check`, `countdown`, `complete`. |
| `epoch` | integer | yes | Unix timestamp when the event should fire. |
| `message` | string | yes | Short human-readable summary (one line). |
| `detail` | string | no | Full self-contained description. Written so that a context-compressed agent can act on it without session memory. Omit for countdown pings where the message is sufficient. |

### Event types

- **`progress`** — periodic check-in during a hold. Typically every 10 min (or 5 min for holds ≤ 30 min).
- **`preflight`** — preparation briefing at T-15 min before a phase transition. Lists equipment, prep tasks, and what to have ready.
- **`ready-check`** — confirmation gate at T-5 min. Cook should acknowledge readiness or request an extension.
- **`countdown`** — final countdown pings at T-4, T-3, T-2, T-1 min. No detail needed.
- **`complete`** — the hold is finished. Triggers the next active phase.

### Ordering and collision rules

Events must be sorted by `epoch` ascending. The cook agent must enforce a 60-second minimum gap between events. If a progress ping would land within 60s of a higher-priority event (preflight, ready-check, countdown, complete), drop the progress ping.

## events.jsonl

Append-only file written by the kicker, read by the cook agent (via poll adapter).

Each line is a self-contained JSON object. One of three types:

### fire

```json
{"type": "fire", "event_id": "preflight-sear", "message": "Pre-flight briefing for sear phase", "detail": "Phase 3 Cast Iron Sear begins in 15 min. Equipment needed: ...", "ts": 1771687201}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | yes | Literal `"fire"`. |
| `event_id` | string | yes | Matches an `id` from schedule.json. |
| `message` | string | yes | Copied from the schedule event. |
| `detail` | string | no | Copied from the schedule event (if present). Duplicated here so the fire event is self-contained — the poll adapter can deliver it without reading schedule.json. |
| `ts` | integer | yes | Unix epoch when the kicker actually fired this event. |

### done

```json
{"type": "done", "reason": "schedule_complete", "ts": 1771688281}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | yes | Literal `"done"`. |
| `reason` | string | yes | One of: `schedule_complete` (all events fired), `shutdown` (received shutdown command). |
| `ts` | integer | yes | Unix epoch. |

### error

```json
{"type": "error", "message": "schedule.json not found or unparseable", "ts": 1771686001}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | yes | Literal `"error"`. |
| `message` | string | yes | Human-readable error description. |
| `ts` | integer | yes | Unix epoch. |

After writing a `done` or `error` event, the kicker must exit.

## control.jsonl

Append-only file written by the cook agent, read by the kicker. The kicker must track its read position (byte offset or line count) and process commands in file order. `shutdown` terminates processing — subsequent commands are ignored.

### shutdown

```json
{"type": "shutdown", "ts": 1771687500}
```

Instructs the kicker to stop. The kicker must:

1. Stop firing new events.
2. Write a `done` event with `reason: "shutdown"`.
3. Exit.

Response time target: kicker should process shutdown within 5 seconds.

### extend

```json
{"type": "extend", "seconds": 300, "ts": 1771687500}
```

Adds `seconds` to the `epoch` of every unfired event in the kicker's in-memory schedule. The kicker must:

1. Identify all events not yet written to events.jsonl.
2. Add `seconds` to each of their `epoch` values.
3. Continue with the adjusted schedule.

Multiple extends are cumulative (each one shifts unfired events by its `seconds` value). Already-fired events are not affected. If `seconds` is negative, the kicker clamps each resulting epoch to `now + 5` minimum (5 seconds; `now` = kicker's wall clock at processing time) to avoid firing events in the past.

## Lifecycle

```text
1. Cook agent creates /tmp/kicker-{session}/
2. Cook agent writes schedule.json (atomic: write to .tmp, mv into place)
3. Cook agent starts kicker process (e.g., python3 kicker.py /tmp/kicker-{session}/)
4. Cook agent starts poll adapter (watches events.jsonl, notifies cook agent)
5. Kicker reads schedule.json, creates empty events.jsonl, begins timing loop
6. Kicker writes fire events to events.jsonl as they come due
7. Poll adapter detects new lines → cook agent processes events
8. Cook agent may write to control.jsonl (shutdown, extend) at any time
9. Kicker writes done event → exits
10. Cook agent detects done → stops poll adapter → removes session directory
```

**Ownership:**

- Steps 1-4, 8, 10: cook agent
- Steps 5-6, 9: kicker
- Step 7: poll adapter (bridge between kicker output and cook agent)

## Atomicity

**Whole-file writes** (schedule.json):

- Write to a temporary file in the session directory (e.g., `schedule.json.tmp`). Temporary files must be in the same directory to guarantee same-filesystem `mv`.
- `mv` the temp file to the final path. On POSIX systems, `mv` within the same filesystem is atomic.

**JSONL appends** (events.jsonl, control.jsonl):

- Open with `O_APPEND` flag and write the complete JSON line (including trailing `\n`) in a single `write()` call. POSIX guarantees atomicity for `O_APPEND` writes under 4096 bytes — protocol lines are well under this limit.
- Do not use `cat >>` or multi-step append patterns, as these may issue multiple `write()` calls.

**Readers:**

- A JSONL file may have a partial last line (incomplete write). Readers must:
  1. Read all complete lines (terminated by `\n`).
  2. Ignore any trailing partial line.
  3. Track position (byte offset or line count) to avoid re-processing.
- `schedule.json` is written once atomically — no partial-read concern after the initial `mv`.

## Kicker Implementation Requirements

A conforming kicker must:

1. Accept a single argument: the session directory path.
2. Read `schedule.json` on startup. Exit with an `error` event if missing or unparseable.
3. Create an empty `events.jsonl` in the session directory before entering the main loop (so the poll adapter can safely start reading).
4. If `events` array is empty, write a `done` event with reason `schedule_complete` and exit immediately.
5. Poll `control.jsonl` at least every 5 seconds for shutdown/extend commands.
6. Fire events by appending to `events.jsonl` when `now >= event.epoch`.
7. Write a `done` event when all events have fired or on shutdown.
8. Exit after writing `done` or `error`.
9. Log diagnostic output to stderr only (stdout is reserved for future use).
10. Have no dependency on Claude Code, Pan Out, or any framework — stdlib only.

## Server Extension

This section describes how a server-based kicker extends the protocol to support phone clients. This is an architectural sketch — not a specification for immediate implementation. The protocol messages and lifecycle are unchanged; the server simply adds a network-facing layer on top.

### Concept

The server IS the kicker process. From the cook agent's perspective, nothing changes — the same `schedule.json` → `events.jsonl` → `control.jsonl` flow runs identically. The server additionally exposes an HTTP/WebSocket API that phone clients connect to.

```text
Cook Agent (Claude Code session)
    │
    ├── writes: schedule.json
    ├── reads:  events.jsonl        ← identical to file-based kicker
    ├── writes: control.jsonl
    │
    ╰── poll-adapter (unchanged)

              ┆ file boundary ┆

Server Kicker Process
    ├── reads:  schedule.json
    ├── writes: events.jsonl        ← fires events on schedule, same as Python kicker
    ├── reads:  control.jsonl
    │
    ├── HTTP API                    ← phone reads schedule, sends ack/extend
    ╰── WebSocket                   ← phone receives live event pushes
```

### Phone → Server (upstream)

Phone clients send actions to the server via HTTP:

- **`POST /ack`** `{"event_id": "ready-check-sear"}` — cook acknowledges a ready-check. Server-internal only — does not surface in `events.jsonl` or any protocol file. The cook agent handles ready-checks through its own conversation flow; phone acks are a UI concern within the server.
- **`POST /extend`** `{"seconds": 300}` — cook requests a time extension from the phone. The server applies this internally by adjusting its in-memory schedule (same logic as processing a `control.jsonl` extend). The server does NOT write to `control.jsonl` — that file remains exclusively written by the cook agent. Phone extends and cook-agent extends are independent: the cook agent may also write extends to `control.jsonl`, and the server processes both sources cumulatively.
- Phone clients cannot trigger **shutdown**. Session lifecycle is controlled exclusively by the cook agent via `control.jsonl`.

### Server → Phone (downstream)

The server pushes state to phone clients via WebSocket:

- **On connect**: server sends the full current state — schedule, which events have fired, time remaining until next event.
- **On event fire**: server pushes the `fire` event object (same shape as the JSONL line) to all connected clients when it fires the event. The `events.jsonl` append is the commit point — if the append fails, the event is not considered fired and no push is sent.
- **On extend/shutdown**: server pushes the updated schedule with recalculated epochs.

### Push notifications

For events that need attention when the phone is locked or the app is backgrounded (preflight, ready-check, complete), the server sends push notifications via platform services (APNs/FCM). The push payload includes the event `message` — enough for the cook to glance at the lock screen and decide whether to open the app.

### What the cook agent side does NOT change

- Same `schedule.json` format.
- Same `events.jsonl` polling via poll adapter.
- Same `control.jsonl` for shutdown/extend.
- The cook agent does not know or care whether the kicker is a Python script, a server, or anything else. The file protocol boundary is the contract.
