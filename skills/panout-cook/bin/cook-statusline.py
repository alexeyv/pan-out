#!/usr/bin/env python3
"""cook-statusline.py — the cook banner, rendered by the harness instead of the model.

Claude Code runs this on every statusline refresh and prints its stdout above the
prompt. It reads the active cook session's state file and renders

    🍲 Beef Stew | PHASE 3: Collagen Conversion | 14:32 | 23min left

computing the wall clock and the countdown at render time, so the banner cannot
go stale, cannot be forgotten on a Q&A turn, and costs no tokens. The cook skill
owns the state file; this script only reads it.

Usage
-----
    <statusline JSON on stdin> | python3 cook-statusline.py

Wire it into a project's `.claude/settings.json` (never the user-level one — the
point is that only this workspace changes):

    {"statusLine": {"type": "command",
                    "command": "python3 '/abs/path/to/cook-statusline.py'",
                    "refreshInterval": 1}}

The quotes around the path are load-bearing: the harness hands this command line
to a shell, and installs live under paths with spaces in them.

Input
-----
The harness's statusline JSON. Two fields matter:

    workspace.project_dir   where `sessions/` lives; `cwd` is the fallback
    model.display_name      shown by the last-resort fallback line

The script may run with a cwd that is not the project, so every path is resolved
from the JSON rather than from the process's own cwd.

Finding the cook
----------------
Candidates are `{project_dir}/sessions/cook-*.md`, newest mtime first (name
breaks ties, so the banner cannot flip between refreshes); the first one whose
front matter says `status: active` *and* is recent wins. Recent means the newer
of the file's mtime and its `phase_end` is within 24h of now — closing a session
is the model's job and models drop it, so `status: active` alone would pin the
banner to a cook that ended days ago. Front matter is the block between the
leading `---` markers, read with a deliberately small parser — `key: value` on
unindented lines, quotes stripped, `null`/`~`/empty read as absent, nested keys
(`last_sensor:` and its children) ignored. Only the first 8192 characters of a
file are read; front matter that has not closed by then is malformed.

Rendered fields: `protocol` and `current_phase` (slugs, title-cased for display),
`phase_index`, `phase_end`, `status`. A file missing `protocol`, or carrying a
`phase_end` that will not parse or sits implausibly far in the future, is
treated as *not active* — the scan moves on rather than showing half a banner or
a confidently wrong countdown. `current_phase` alone is optional; without it the
phase slot is dropped, as is the `PHASE N:` prefix when `phase_index` is absent
or absurd.

Timer slot, from `phase_end` minus now:

    >= 5 min      `23min left`     whole minutes, truncated
    < 5 min       `3:47 left`      M:SS, so the last minutes read precisely
    past due      `+6min over`     truncated, floored at 1 — never `+0min over`
    > 1h past due `+3h over`       whole hours; `+188min over` is just noise
    null / absent slot omitted entirely (open-ended phase)

No active cook
--------------
The script chains, preferring the command it displaced:

    {project_dir}/.claude/panout-statusline.json  {"chain_to": "<command line>"}
    ~/.claude/settings.json                       statusLine.command

The sidecar is written by the help skill when installing over an existing
*project* statusline — that entry is overwritten, so this file is the only
record of it. Whichever command is found runs through a shell with the *same
stdin bytes* this script received, and its stdout passes through verbatim
(multi-line output included). So outside a live cook the user sees exactly the
statusline they configured for themselves, and installing this one costs them
nothing. `~/.claude/settings.json` is never written.

If the chain is absent, produces nothing, fails, or takes longer than 2s, the
last resort is a plain `{dir} | {model}` line. A chained command that is this
script again (a user who wired it up globally) is not re-entered — the child sees
PANOUT_STATUSLINE_CHAIN in its environment and skips straight to the fallback.

Failure policy
--------------
Exit status is always 0 and stdout is never empty. Every failure path — bad JSON,
unreadable state file, broken front matter, a crash anywhere — degrades to the
chain and then to the fallback line; a crash in the session scan still gets the
chain its turn. Diagnostics go to stderr, which the harness discards; nothing but
the banner reaches stdout. Python 3 stdlib only, macOS and Linux.
"""

import json
import os
import sys
from datetime import datetime
from pathlib import Path

# The last-minutes format takes over below this many seconds remaining.
FINAL_STRETCH_SECONDS = 300
# Past this much overrun the count reads in hours instead of minutes.
OVERDUE_HOURS_AFTER_SECONDS = 3600
# A deadline further ahead than this is a typo in the year or the date, not a
# hold anyone is cooking; a countdown built on it would be confidently wrong.
# A week is deliberately far past the longest real phase (a cure, a ferment)
# and far short of the mistake it catches — a year in the wrong field.
MAX_REMAINING_SECONDS = 604800
# A session nobody has written to and whose deadline has not moved inside this
# window is over, whatever its `status` says: closing a session is a model
# obligation and models drop it, which is how a finished cook ends up pinned to
# the statusline for weeks. Generous on purpose — overnight brines and long
# holds are real cooks, and every state write moves the mtime.
STALE_AFTER_SECONDS = 86400
# Front matter lives in the first few hundred characters; anything past this is
# body. Characters, not bytes — the read is decoded text.
FRONTMATTER_CHARS = 8192
# Plenty for a real sessions/ directory, and a bound on a pathological one.
MAX_SESSION_FILES = 200
# A statusline that blocks is worse than one that is plain.
CHAIN_TIMEOUT_SECONDS = 2.0
# Set in the chained child so a globally-installed copy cannot recurse.
CHAIN_GUARD_ENV = "PANOUT_STATUSLINE_CHAIN"
# Our own file, next to the harness's settings: the project statusline this one
# replaced. Not a key in settings.json — that file belongs to the harness.
SIDECAR_PARTS = (".claude", "panout-statusline.json")

TIMESTAMP_FORMATS = (
    "%Y-%m-%dT%H:%M:%S%z",
    "%Y-%m-%dT%H:%M:%S.%f%z",
    "%Y-%m-%dT%H:%M:%S",
    "%Y-%m-%dT%H:%M:%S.%f",
    "%Y-%m-%dT%H:%M%z",
    "%Y-%m-%dT%H:%M",
)

# The banner carries an emoji; a statusline is no place for a UnicodeEncodeError.
for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        try:
            _stream.reconfigure(encoding="utf-8", errors="replace")
        except (OSError, ValueError):
            pass


def note(message):
    """One line of diagnostics. The harness discards stderr; stdout stays clean."""
    try:
        print("cook-statusline: %s" % message, file=sys.stderr, flush=True)
    except Exception:  # noqa: BLE001 — diagnostics must never be the failure
        pass


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

def read_stdin_bytes():
    """The raw statusline JSON. The chained command needs these exact bytes."""
    try:
        stream = sys.stdin
        if stream is None or stream.isatty():
            return b""
        buffer = getattr(stream, "buffer", None)
        if buffer is not None:
            return buffer.read()
        return (stream.read() or "").encode("utf-8")
    except Exception as exc:  # noqa: BLE001 — no stdin is a fallback, not a crash
        note("cannot read stdin: %r" % (exc,))
        return b""


def parse_payload(raw):
    try:
        text = raw.decode("utf-8", "replace").strip()
        if not text:
            return {}
        data = json.loads(text)
    except (ValueError, AttributeError):
        return {}
    return data if isinstance(data, dict) else {}


def resolve_root(payload):
    """Project root: `workspace.project_dir`, then `cwd`, then this process's cwd.

    `project_dir` first and not merely as a synonym for `cwd`: a cook who has
    cd'd into a subdirectory is still cooking, and the banner has to survive it.
    """
    workspace = payload.get("workspace")
    candidates = []
    if isinstance(workspace, dict):
        candidates.append(workspace.get("project_dir"))
    candidates.append(payload.get("cwd"))
    for value in candidates:
        if isinstance(value, str) and value.strip():
            try:
                path = Path(value).expanduser()
            except (OSError, ValueError):
                continue
            if path.is_dir():
                return path
    try:
        return Path.cwd()
    except OSError:
        return Path(".")


def display_model(payload):
    model = payload.get("model")
    if isinstance(model, dict):
        name = model.get("display_name")
        if isinstance(name, str) and name.strip():
            return name.strip()
    return None


# ---------------------------------------------------------------------------
# State file
# ---------------------------------------------------------------------------

def scalar(raw):
    """A front-matter value: quotes stripped, comments dropped, null-ish -> None."""
    text = raw.strip()
    if not text:
        return None
    if text[0] in "\"'":
        quote = text[0]
        end = text.find(quote, 1)
        return text[1:end] if end != -1 else None
    comment = text.find(" #")
    if comment != -1:
        text = text[:comment].rstrip()
    if not text or text.startswith("#"):
        return None
    if text.lower() in ("null", "~", "none"):
        return None
    return text


def read_frontmatter(path):
    """Top-level scalars from the YAML front matter, or None if there is none."""
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as handle:
            head = handle.read(FRONTMATTER_CHARS)
    except OSError:
        return None

    lines = head.splitlines()
    index = 0
    while index < len(lines) and not lines[index].strip():
        index += 1
    if index >= len(lines) or lines[index].strip() != "---":
        return None

    fields = {}
    for line in lines[index + 1:]:
        stripped = line.strip()
        if stripped in ("---", "..."):
            return fields
        # Indented lines belong to a nested key (last_sensor:); blanks and
        # whole-line comments carry nothing.
        if not stripped or line[:1] in (" ", "\t") or stripped.startswith("#"):
            continue
        key, separator, value = stripped.partition(":")
        if separator:
            fields[key.strip()] = scalar(value)
    # Front matter never closed inside what we read: a truncated write, or a
    # body long enough to push the closing marker past FRONTMATTER_CHARS.
    note("front matter never closed in %s" % path.name)
    return None


def parse_timestamp(text):
    """ISO 8601 as the cook skill writes it (±HHMM, no colon). Naive means local."""
    if not isinstance(text, str):
        return None
    candidate = text.strip().replace(" ", "T", 1)
    for fmt in TIMESTAMP_FORMATS:
        try:
            moment = datetime.strptime(candidate, fmt)
        except ValueError:
            continue
        return moment.astimezone() if moment.tzinfo is None else moment
    return None


def titleize(slug):
    """`sous-vide-bath` -> `Sous Vide Bath`, leaving existing capitals alone."""
    words = slug.replace("_", " ").replace("-", " ").split()
    return " ".join(word[:1].upper() + word[1:] for word in words)


def phase_number(raw):
    """`phase_index` for display, or None when it is absent, unparseable or absurd."""
    try:
        number = int(str(raw).strip())
    except (TypeError, ValueError):
        return None
    # No protocol has a negative or three-digit phase; such a value is corrupt
    # state, and `PHASE -1:` in front of a real phase name helps nobody.
    return number if 0 <= number <= 99 else None


def timer_slot(phase_end, now):
    """The countdown, or None when the deadline is too far out to be believed."""
    remaining = int((phase_end - now).total_seconds())
    if remaining < 0:
        overrun = -remaining
        if overrun >= OVERDUE_HOURS_AFTER_SECONDS:
            return "+%dh over" % (overrun // 3600)
        # Truncated like the others, but floored at 1: "+0min over" would read
        # as a rounding bug rather than as an overrun.
        return "+%dmin over" % max(1, overrun // 60)
    if remaining > MAX_REMAINING_SECONDS:
        return None
    if remaining >= FINAL_STRETCH_SECONDS:
        return "%dmin left" % (remaining // 60)
    return "%d:%02d left" % divmod(remaining, 60)


def render(fields, now):
    """The banner for one active state file, or None if it cannot be trusted."""
    protocol = fields.get("protocol")
    # A slug of nothing but separators titleizes to "" — an emoji with no dish.
    dish = titleize(protocol) if protocol else ""
    if not dish:
        return None

    segments = ["🍲 " + dish]

    phase = fields.get("current_phase")
    label = titleize(phase) if phase else ""
    if label:
        number = phase_number(fields.get("phase_index"))
        segments.append(label if number is None else "PHASE %d: %s" % (number, label))

    segments.append(now.strftime("%H:%M"))

    phase_end = fields.get("phase_end")
    if phase_end is not None:
        moment = parse_timestamp(phase_end)
        if moment is None:
            # An unreadable deadline would silently show the wrong countdown.
            return None
        slot = timer_slot(moment, now)
        if slot is None:
            # A deadline a year out is a typo, and "525600min left" next to a
            # dish name reads as the banner being broken, which it is.
            return None
        segments.append(slot)

    return " | ".join(segments)


def is_stale(fields, mtime, now):
    """True when neither the file nor its deadline has moved inside the window."""
    freshest = mtime
    moment = parse_timestamp(fields.get("phase_end"))
    if moment is not None:
        freshest = max(freshest, moment.timestamp())
    return (now.timestamp() - freshest) > STALE_AFTER_SECONDS


def active_banner(payload, now):
    sessions = resolve_root(payload) / "sessions"
    if not sessions.is_dir():
        return None

    candidates = []
    try:
        for entry in sessions.glob("cook-*.md"):
            try:
                candidates.append((entry.stat().st_mtime, entry.name, entry))
            except OSError:
                continue
            # The cap has to bite during enumeration, not after it: a
            # pathological sessions/ must not cost a stat() per file. Beyond
            # the cap "newest first" is only over what was enumerated.
            if len(candidates) >= MAX_SESSION_FILES:
                note("more than %d session files; scanning only that many" % MAX_SESSION_FILES)
                break
    except OSError as exc:
        note("cannot list %s: %r" % (sessions, exc))
        return None

    # Name breaks an mtime tie so two sessions written in the same second
    # cannot swap the banner back and forth between refreshes.
    candidates.sort(key=lambda item: (item[0], item[1]), reverse=True)
    for mtime, _, path in candidates:
        fields = read_frontmatter(path)
        if not fields:
            continue
        status = fields.get("status")
        if not isinstance(status, str) or status.strip().lower() != "active":
            continue
        if is_stale(fields, mtime, now):
            note("ignoring stale active state file %s" % path.name)
            continue
        banner = render(fields, now)
        if banner:
            return banner
        note("ignoring malformed active state file %s" % path.name)
    return None


# ---------------------------------------------------------------------------
# No active cook: hand the turn back to the statusline that was here first
# ---------------------------------------------------------------------------

def project_chain_command(root):
    """`chain_to` from our sidecar: the project statusline the install replaced."""
    path = root.joinpath(*SIDECAR_PARTS)
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except OSError:
        return None  # no sidecar is the common case, not a diagnostic
    except ValueError as exc:
        note("unreadable sidecar %s: %r" % (path, exc))
        return None
    if isinstance(data, dict):
        command = data.get("chain_to")
        if isinstance(command, str) and command.strip():
            return command
    note("sidecar %s carries no usable chain_to" % path)
    return None


def user_statusline_command():
    """`statusLine.command` from `~/.claude/settings.json`. Read-only, always."""
    try:
        path = Path(os.path.expanduser("~")) / ".claude" / "settings.json"
        settings = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        note("no chainable user statusline: %r" % (exc,))
        return None
    if not isinstance(settings, dict):
        return None
    entry = settings.get("statusLine")
    if not isinstance(entry, dict):
        return None
    command = entry.get("command")
    if isinstance(command, str) and command.strip():
        return command
    return None


def chain_command(payload):
    """What to hand the line to: the displaced project command, else the user's."""
    return project_chain_command(resolve_root(payload)) or user_statusline_command()


def kill_process_group(process):
    """Kill the chained command *and* whatever it spawned, then reap it."""
    import signal  # noqa: PLC0415 — only the timeout path needs it

    try:
        os.killpg(os.getpgid(process.pid), signal.SIGKILL)
    except (OSError, AttributeError):
        try:
            process.kill()
        except OSError:
            pass
    try:
        process.communicate(timeout=CHAIN_TIMEOUT_SECONDS)
    except Exception:  # noqa: BLE001 — a stray zombie beats a blank statusline
        pass


def chain(raw, payload):
    """Run the displaced statusline with our stdin; return its stdout, or None."""
    if os.environ.get(CHAIN_GUARD_ENV):
        return None
    command = chain_command(payload)
    if not command:
        return None

    import subprocess  # noqa: PLC0415 — kept off the hot path's import cost

    environment = dict(os.environ)
    environment[CHAIN_GUARD_ENV] = "1"
    try:
        # shell=True because the configured command is a command line, not an
        # argv — a bare name has to resolve through PATH like the harness does.
        # start_new_session gives it its own process group: killing the shell
        # on a timeout would otherwise leave its children running, and at
        # refreshInterval 1 those orphans pile up once a second.
        process = subprocess.Popen(
            command,
            shell=True,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            env=environment,
            start_new_session=True,
        )
    except Exception as exc:  # noqa: BLE001 — OSError, ValueError, anything at all
        note("cannot start chained statusline: %r" % (exc,))
        return None

    try:
        stdout, _ = process.communicate(input=raw, timeout=CHAIN_TIMEOUT_SECONDS)
    except Exception as exc:  # noqa: BLE001 — timeout, OSError, anything at all
        note("chained statusline failed: %r" % (exc,))
        kill_process_group(process)
        return None

    text = (stdout or b"").decode("utf-8", "replace").rstrip("\n")
    return text or None


def fallback_line(payload):
    """Last resort. Whatever else went wrong, this line always prints."""
    try:
        root = resolve_root(payload)
        name = root.name or str(root)
    except Exception:  # noqa: BLE001
        name = ""
    parts = [part for part in (name, display_model(payload)) if part]
    return " | ".join(parts) if parts else "claude"


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def emit(line):
    try:
        print(line, flush=True)
    except Exception:  # noqa: BLE001
        # Even a broken encoder must not leave the statusline blank.
        try:
            sys.stdout.buffer.write(line.encode("utf-8", "replace") + b"\n")
            sys.stdout.buffer.flush()
        except Exception:  # noqa: BLE001
            pass


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if "-h" in argv or "--help" in argv:
        # `python3 -OO` strips docstrings; --help is still not allowed to fail.
        print((__doc__ or "cook-statusline.py — contract in the source.").strip())
        return 0

    payload = {}
    raw = b""
    try:
        raw = read_stdin_bytes()
        payload = parse_payload(raw)
        banner = active_banner(payload, datetime.now().astimezone())
        if banner:
            emit(banner)
            return 0
    except Exception as exc:  # noqa: BLE001 — a statusline never shows a traceback
        note("crashed: %r" % (exc,))

    # Its own try: a crash above must not cost the user their own statusline.
    try:
        chained = chain(raw, payload)
        if chained:
            emit(chained)
            return 0
    except Exception as exc:  # noqa: BLE001
        note("chain crashed: %r" % (exc,))

    emit(fallback_line(payload))
    return 0


if __name__ == "__main__":
    sys.exit(main())
