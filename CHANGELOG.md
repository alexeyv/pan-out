# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- `bin/hold-timer.py` — passive-phase hold timer that runs under the Claude Code Monitor tool: every event wakes the cook agent directly. Configurable heartbeat tick as a liveness signal, spoken event announcements, a completion alarm that nags until acknowledged, and wall-clock-anchored timing that detects a suspended machine or a stepped clock and reports the gap instead of firing late in silence
- `test/timer/run-tests.sh` — timer test suite covering event timing, heartbeat, silent mode, suspend/resume gap recovery, nag persistence, and unusable schedules

### Changed
- Cook skill timer integration rewritten around Monitor: the timer wakes the agent instead of the agent polling for events. Acknowledging a finished hold and extending one are both TaskStop plus re-arm
- Passive-phase timer modes reduced from three to two — Monitor-driven and manual phone timer
- `timer_mode` state values are now `monitor-timer | manual`, and cook state carries `timer_task_id` so a context-compressed session can still stop the timer it armed

### Removed
- Kicker timer stack: `bin/kicker.py`, `bin/poll-adapter.py`, `bin/progress-timer.sh`, and `kicker-protocol.md`. The file-based schedule/events/control protocol existed because nothing could wake a sleeping agent; Monitor can, so the whole layer is gone

## [0.1.2] - 2026-03-24

### Changed
- Cook skill prompt compressed from 555 to 186 lines (66% reduction) with no behavioral difference
- Recipe workflow and cook state consistency improvements
- Inline `instructions.md` into SKILL.md across skills

### Fixed
- Attention chime (`Glass.aiff`) added to `speak.sh` for kitchen salience on macOS
- `step_index` now maintained inline during active pull-mode phases for reliable crash recovery
- Docs site: removed theme gem reference breaking GitHub Pages build
- Homepage: prefixed `/help` with `panout-`

### Docs
- Rewritten setup page with guided onboarding flow
- Help skill section added to homepage
- Deep links from README to panout.org doc pages
- Profile update guidance added to setup page

## [0.1.1] - 2026-02-27

### Added
- Push-mode photo capture skill (`/panout-capture-photo`)
- Kicker agent for passive phase timers with precision sleep and countdown acceleration
- Mandatory pre-flight briefing at passive phase entry
- Status banner and task list formatting during cook sessions
- Adversarial review step after protocol compilation
- Protocol principles reference wired into recipe compilation
- Glossary-aware recipe compilation (terms treated as assumed knowledge)
- Research file support for protocols
- Intent detection for help and cook routing
- Cross-platform TTS: espeak support for Linux, platform-adaptive alert sounds
- New user onboarding flow with cook profile and calibration setup
- Phase timing fields in protocol format specification
- Documentation site at [panout.org](https://panout.org)

### Changed
- All skill names namespaced as `panout-*` to avoid built-in clashes
- Recipe review split into parallel audit and adversarial subagents
- Cook skill now distinguishes protocol (template) from plan (today's cook)

### Fixed
- Timer backgrounding clarified to prevent false completion reports
- Kicker now calls TaskUpdate for fired events; short-hold floor rule added
- Missing state file fields and kicker schedule safeguards
- Slash commands added to help and recipe handoff text
- Argument-hint added to help and debrief for autocomplete visibility
- Calibration reads removed from recipe and debrief skills
- Calibration language and paths aligned across docs and skills

## [0.1.0] - 2026-02-17

### Added
- Core skill set: cook, recipe, debrief, help
- Protocol format specification and YAML schema
- Example protocols: beef stew, bolognese
- Background timer with TTS announcements
- Food safety reference (USDA/FDA minimums)
- Example cook profile and calibration templates
- Test harnesses for cook simulation and end-to-end pipeline
