# Protocol Format Reference

Protocols are stored as Markdown files with YAML front matter in `protocols/`. Every dish has two files:

1. **`{dish}.md`** — the executable protocol (front matter + Markdown body)
2. **`{dish}-science.md`** — the science deep-dive (physics, chemistry, failure modes, food safety)

The science file is the **arbiter**: if there is any conflict between the protocol body and the science file on temperatures, safety, or chemistry, the science file wins. Update both when changing parameters.

---

## Design Principles

- **Personal, not universal**: A protocol is specific to this cook and this kitchen. It encodes the equipment available, the calibration offsets of these sensors, the quirks of this stove, and the lessons learned from previous cooks. It is not a generic recipe — it is a flight plan tuned to this aircraft.
- **Living document**: Protocols are refined through trial and error. Each cook is an opportunity to update timings, temps, techniques, and notes. The recipe skill creates them; the cook skill executes them; the debrief skill captures what to change next time. No protocol is ever "finished."
- **Agent-optimized**: Structured for LLM consumption, not human reading
- **Human-viewable on demand**: The cook can ask to see a summary at any time
- **Carries its own scaling logic**: Quantities + principles, not just numbers
- **Phase-based**: Every cook is a sequence of phases, each with distinct character

---

## File 1: `{dish}.md` — Protocol

### Front Matter (YAML)

```yaml
---
name: "Dish Name"
description: "One-line description"
serves: 4
total_time: "3h 15m"
source: "Origin of this protocol (research session, adapted from, etc.)"
science: "dish-name-science.md"   # companion science file in same directory

# Revision history — appended by debrief skill after each cook
revision_history: []
# Example entry:
#   - date: "2026-02-16"
#     cook_session: "cook-2026-02-16-beef-stew.md"
#     changes:
#       - "Increased braise duration from 90m to 100m"
#       - "Added equipment_note about cast iron overshoot to sear phase"
#     evidence: "Beef not fork-tender at 90min. Needed 100min for 900g chuck."

# Equipment needed — checked at session start
equipment:
  - dutch-oven-5L
  - thermocouple
  - ir-thermometer
  - cutting-board

# Phases flat list — used by cook skill for structure (body has full detail)
phases:
  - id: prep
    name: "Mise en Place"
    type: active          # active = pull mode, passive = push mode
    duration: "15-20m"
  - id: sear
    name: "Maillard Phase"
    type: active
    duration: "15-20m"
  - id: braise
    name: "Collagen Conversion"
    type: passive
    duration: "90m"
    duration_range: "75-120m"
    timer_seconds: 5400   # 90 minutes
  - id: rest-season
    name: "Rest & Season"
    type: passive
    duration: "15m"
    timer_seconds: 900
  - id: optional-phase-example
    name: "Optional Phase Example"
    type: active
    duration: "10m"
    optional: true   # When true, cook skill presents this phase as skippable and asks the cook whether to include it before starting

# Scaling block
scaling:
  base_serves: 4
  base_protein_g: 900
  principle: "Scale everything to protein weight. Liquid covers meat by 2cm regardless of quantity."

---
```

### Body (Markdown)

The body is structured as `## Phase: [Name]` sections, with the full narrative, steps, and sensory cues. The cook skill parses these sections by name, matched to the front matter `phases` list.

#### Sensor targets in the body

Bold sensor targets use the pattern `**Target: 90°C (TC)**` where:
- The temperature is the **actual/true temperature** (not instrument-adjusted)
- The parenthetical is the sensor type: `TC` (thermocouple), `IR` (infrared)
- Calibration is applied at runtime by the cook skill — never bake offsets into the protocol

Example body structure:

```markdown
## Overview

Brief dish narrative. What makes this dish work. What the cook needs to understand before starting.

## Ingredients

| Item | Quantity | Role | Notes |
|------|----------|------|-------|
| Chuck beef | 900g | primary-protein | Cut against grain. Connective tissue = flavor after braising. |
| Yellow onion | 2 medium (~300g) | aromatic-base | Substitutes: shallots (sweeter), leeks (milder) |
| Beef stock | 750ml | braising-liquid | Low-sodium preferred — season at end |

**Scaling principles:** [prose describing scaling logic]

## Phase: Mise en Place

**Type:** active | **Duration:** 15-20 min

Briefing: We're cutting and organizing before any heat. Once the sear starts, it's continuous. Bone-dry beef surfaces are the single most important prep step for browning.

1. **Cube the beef into 3cm pieces** (900g → ~30 cubes)
   - Technique: Cut against visible grain lines
   - *Sensory: Each cube roughly thumb-knuckle sized*

2. **Pat beef completely dry with paper towels**
   - Science: Surface moisture creates steam which prevents Maillard browning. Need >140°C at surface, impossible through a water layer.
   - *Sensory: Paper towel comes away without wet spots. Surface feels tacky, not slick.*

## Phase: Collagen Conversion

**Type:** passive | **Duration:** 90 min (range: 75–120 min) | **Timer:** 90:00

**Target: 88–92°C (TC)**

Briefing: Low and slow. Collagen converts to gelatin at 80-90°C over time. The liquid should barely simmer — lazy bubbles, not a rolling boil. You can walk away. I'll check in every 15 minutes.

1. **Return beef to pot, add stock** — liquid should cover meat by ~2cm
2. **Bring to gentle simmer on MEDIUM, reduce to LOW before hitting 90°C**
   - *Sensory: Lazy bubbles every 2-3 seconds. Steam wisps, not clouds.*
   - Equipment note: Cast iron dutch oven has massive thermal inertia. Reduce burner BEFORE hitting 90°C — residual heat carries it up 3-5°C.
3. **Lid on, slight crack for steam release**

## Equipment Notes

[Specific equipment behavior notes for this dish — cast iron quirks, sensor placement, etc.]

## Storage & Reheating

[How to store leftovers, how long they keep, how to reheat without ruining texture.]

## Debrief Notes

*Skills append here after cooks. Do not edit manually.*

## Substitutions

*Skills append confirmed substitution outcomes here.*

## Scaling Notes

*Skills append confirmed scaling experiences here.*
```

---

## File 2: `{dish}-science.md` — Science Deep-Dive

The science file is the **arbiter** for all scientific claims in the protocol. When the cook asks "why" questions, when the debrief skill considers protocol changes, and when the recipe skill creates or revises protocols — the science file is consulted first.

```markdown
# {Dish Name} — Science & Principles

Source: Compiled from web research by recipe skill
Date: {date}
Protocol: protocols/{dish}.md

## Physics & Chemistry

What transformations happen and why. Heat transfer mechanisms,
protein behavior, chemical reactions. Quantitative where possible.

## Critical Control Points

3-5 key variables that determine success or failure.
Each with: target, tolerance, what happens outside tolerance.

## Failure Modes

| Problem | Cause | Diagnostic Cue | Prevention/Recovery |
|---------|-------|----------------|---------------------|
| ... | ... | ... | ... |

## Food Safety

Relevant USDA/FDA temps. Time-temperature equivalents if applicable.
When to be vigilant vs. when physics has you covered.

## Ingredient Notes

Functional roles of key ingredients. Substitution logic.
Scaling principles. What's load-bearing vs. adjustable.

## Sources

Numbered list with URLs.
```

---

## Canonical Example

`protocols/beef-stew.md` + `protocols/beef-stew-science.md` are the structural gold standard. When in doubt, look at how they're organized.

---

## Key Conventions

### Phase Types
- `active` → Pull mode. Cook is hands-on. One instruction at a time.
- `passive` → Push mode. Timer-driven. Pre-flight briefings. Cook can leave.

### Optional Phases
A phase may carry `optional: true` in the front matter phases list. When the cook skill encounters an optional phase, it must:
1. Announce the phase as optional and briefly explain its purpose.
2. Ask the cook whether to include it: "This phase is optional. Want to include it?"
3. If the cook declines, skip the phase entirely and advance to the next one.
4. If the cook accepts, execute it normally.

Example use: liquid reductions (milk, wine) in bolognese that improve the dish but can be skipped for simplicity.

### Burner Settings
Include explicit burner settings on steps that involve heat changes. Use plain language: `"high"`, `"medium"`, `"low"`, `"medium → low"`, `"off"`. Never assume the cook knows what burner setting produces a target temperature — tell them directly.

### Sensor Targets
Always specify the **actual/true temperature**, not an instrument-adjusted reading. Calibration is applied at runtime by the cook skill, which reads `calibration.md` and presents both values to the cook: "We want X°C (about Y°C on your thermocouple)." Protocols never contain instrument-specific offsets — they stay correct even when instruments are recalibrated or replaced.

In the body, use bold format: `**Target: 90°C (TC)**`

### Scaling Principles
The protocol carries `scaling_principle` logic in ingredients and a `scaling:` block in front matter. The LLM uses these to reason about scaling, not a formula engine.

### Briefings
Every phase has a briefing paragraph — delivered at phase entry and during preceding idle time as a pre-flight briefing.

### Duration vs Duration Range
`duration` is the expected time. `duration_range` is the acceptable window. The agent uses sensory cues and sensor data to decide when to actually transition, not just the clock.

### Skills-Append-Over-Time Sections
Three sections at the bottom of the protocol body accumulate knowledge from cooks over time:
- **Debrief Notes** — written by the debrief skill after each cook (appended, never overwritten)
- **Substitutions** — confirmed substitution outcomes from actual cooks
- **Scaling Notes** — scaling experiences and adjustments from actual cooks

These sections grow over time and are never manually edited. They form the dish's learning trail.

### Science File as Arbiter
If any step in the protocol body contradicts the science file (temperatures, safety targets, chemistry claims), the science file takes precedence. When the debrief skill proposes a protocol change, it must check the science file first and surface any contradiction to the cook before proceeding.

### Revision History
The `revision_history` field in front matter tracks protocol evolution across cooks. Each entry records what changed, why, and which cook session motivated it.

```yaml
revision_history:
  - date: "2026-02-16"
    cook_session: "cook-2026-02-16-beef-stew.md"
    changes:
      - "Increased braise duration from 90m to 100m"
      - "Added equipment_note about cast iron overshoot to sear phase"
    evidence: "Beef not fork-tender at 90min. Needed 100min for 900g chuck."
```

**Fields per entry:**
- `date` — when the update was made
- `cook_session` — session state file that motivated the change (for traceability)
- `changes` — list of human-readable descriptions of what was modified
- `evidence` — the observation or cook feedback that justified the change

**Any skill that modifies a protocol MUST append a `revision_history` entry.** This includes the debrief skill (post-cook updates), the recipe skill (refine mode), or any other skill that changes protocol values. Entries are never removed — they form an audit trail.

### Backward Compatibility
The cook skill supports both `.md` and `.yaml` protocol formats. When loading a protocol, it tries `.md` first, then falls back to `.yaml`. New protocols are always created as `.md`.
