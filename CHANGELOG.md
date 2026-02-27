# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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
