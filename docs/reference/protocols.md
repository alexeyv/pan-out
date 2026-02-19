---
layout: default
title: Protocol Format
parent: Reference
nav_order: 1
---

# Protocol format

Protocols are YAML files that encode everything needed to execute a dish. They're the contract between the recipe skill (which creates them) and the cook skill (which runs them).

This page is for people who want to read, edit, or write protocols by hand. If you're just cooking, the skills handle all of this for you.

## Design principles

- **Personal, not universal.** A protocol is tuned to a specific kitchen — your equipment, your sensors, your lessons learned. It's not a generic recipe; it's a flight plan for this aircraft.
- **Living document.** Protocols improve through use. Each cook is a chance to refine timings, temperatures, and technique notes.
- **Agent-optimized.** Structured for LLM consumption, but human-readable on demand.
- **Phase-based.** Every cook is a sequence of phases, each with a distinct character and execution mode.

## Top-level fields

```yaml
name: "Beef Stew"
description: "Collagen braise with Maillard sear"
serves: 4
total_time: "3h 15m"
source: "Research compiled in protocols/beef-stew-research.md"
revision_history: []
```

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Dish name |
| `description` | Yes | One-line summary |
| `serves` | Yes | Base serving count |
| `total_time` | Yes | Estimated total duration |
| `source` | Yes | Where this protocol came from |
| `revision_history` | Yes | Changelog populated by the debrief skill (starts empty) |

## Equipment

A list of equipment IDs checked at session start:

```yaml
equipment:
  - dutch-oven-5L
  - thermocouple
  - ir-thermometer
  - cutting-board
```

## Ingredients

Each ingredient carries its functional role and scaling logic:

```yaml
ingredients:
  - item: chuck beef
    quantity: "900g"
    role: primary-protein
    scaling_principle: "Main mass. Everything else scales relative to this."
    notes: "Cut against grain for serving"

  - item: yellow onion
    quantity: "2 medium (~300g)"
    role: aromatic-base
    scaling_principle: "Aromatics at ~10% of total volume"
    substitutes: ["shallots (sweeter)", "leeks (milder)"]
```

| Field | Required | Description |
|-------|----------|-------------|
| `item` | Yes | Ingredient name |
| `quantity` | Yes | Amount for base serving count |
| `role` | Yes | Functional role (primary-protein, aromatic-base, braising-liquid, seasoning, etc.) |
| `scaling_principle` | Yes | *Why* the quantity is what it is — used by the LLM to reason about scaling |
| `notes` | No | Preparation or usage notes |
| `substitutes` | No | Alternative ingredients with flavor/texture impact notes |

## Phases

The execution backbone. Each phase has a type that determines the cook skill's execution mode:

- **`active`** (prep, sear, saute, assemble) = **pull mode** — one instruction at a time, cook confirms before advancing
- **`passive`** (braise, rest, marinate, rise) = **push mode** — timer runs in background, skill pushes periodic updates

```yaml
phases:
  - id: sear
    name: "Maillard Phase"
    type: active
    duration: "15-20m"
    briefing: |
      High heat, small batches, don't crowd the pan.
      We want mahogany browning on at least two faces per cube.
    steps:
      - instruction: "Sear beef in 2-3 batches, 90-120s per face"
        batch_size: "10-12 cubes max"
        sensory_cue: "Mahogany brown crust, releases from pan without sticking"
        science: "Maillard reaction requires >140C and dry surface."
```

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique phase identifier |
| `name` | Yes | Human-readable phase name |
| `type` | Yes | `active` or `passive` |
| `duration` | Yes | Expected duration |
| `duration_range` | No | Acceptable duration window (for passive phases) |
| `briefing` | Yes | Delivered at phase entry — sets context and expectations |
| `steps` | Yes | Ordered list of steps |
| `temp_target` | No | Target temperature with sensor type |
| `sensor_schedule` | No | Polling interval and action for passive phases |
| `timer` | Required for passive | Timer with `duration_seconds` and `label` |

## Steps

Steps are the atomic instructions within phases:

| Field | Required | Description |
|-------|----------|-------------|
| `instruction` | Yes | What to do |
| `sensory_cue` | Recommended | What the cook should see, smell, hear, or feel |
| `science` | No | Why this works — the underlying mechanism |
| `technique` | No | Mechanical how-to for non-obvious actions |
| `sensor_check` | No | Temperature check with `type` (tc/ir) and `target` |
| `equipment_note` | No | Cookware-specific behavior (e.g., cast iron thermal inertia) |
| `burner` | When applicable | Explicit setting for heat changes (`"high"`, `"medium"`, `"off"`) |
| `batch_size` | No | For batched operations (e.g., searing) |
| `duration` | No | Expected time for this step |
| `quantity` | No | Amounts relevant to this step |
| `scaling_note` | No | How to adjust for different quantities |

## Temperature conventions

**Protocols always store actual/true temperatures** — what the food or surface really is, not what any instrument displays.

- A braise target of 90C means 90C actual
- A sear surface target of 220C means 220C actual

Calibration is applied at runtime by the cook skill, which reads the cook's `calibration.md` and presents both values: *"We want 90C actual (about 86-87C on your thermocouple)."* This keeps protocols correct even when instruments are recalibrated or replaced.

## Revision history

The debrief skill appends an entry after each cook:

```yaml
revision_history:
  - date: "2026-02-16"
    cook_session: "cook-2026-02-16-beef-stew.md"
    changes:
      - "Increased braise duration from 90m to 100m"
      - "Added equipment_note about cast iron overshoot to sear phase"
    evidence: "Beef not fork-tender at 90min. Needed 100min for 900g chuck."
```

| Field | Description |
|-------|-------------|
| `date` | When the update was made |
| `cook_session` | Session state file that motivated the change |
| `changes` | Human-readable list of what was modified |
| `evidence` | The observation that justified the change |

Entries are never removed — they form an audit trail of how the protocol evolved through actual cooking.
