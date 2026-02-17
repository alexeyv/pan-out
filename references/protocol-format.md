# Protocol Format Reference

Protocols are YAML files stored in `protocols/`. They are the contract between the `recipe` skill (which creates them) and the `cook` skill (which executes them).

## Design Principles

- **Personal, not universal**: A protocol is specific to this cook and this kitchen. It encodes the equipment available, the calibration offsets of these sensors, the quirks of this stove, and the lessons learned from previous cooks. It is not a generic recipe — it is a flight plan tuned to this aircraft.
- **Living document**: Protocols are refined through trial and error. Each cook is an opportunity to update timings, temps, techniques, and notes. The recipe skill creates them; the cook skill executes them; the debrief skill captures what to change next time. No protocol is ever "finished."
- **Agent-optimized**: Structured for LLM consumption, not human reading
- **Human-viewable on demand**: The cook can ask to see a summary at any time
- **Carries its own scaling logic**: Quantities + principles, not just numbers
- **Phase-based**: Every cook is a sequence of phases, each with distinct character

## Format

```yaml
name: "Dish Name"
description: "One-line description"
serves: 4
total_time: "3h 15m"
source: "Origin of this protocol (research session, adapted from, etc.)"

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

# Ingredients with functional roles for intelligent substitution
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

  - item: beef stock
    quantity: "750ml"
    role: braising-liquid
    scaling_principle: "Liquid covers meat by 2cm"
    notes: "Low-sodium preferred — season at end"

  - item: salt
    quantity: "to taste"
    role: seasoning
    scaling_principle: "1.5% of protein weight as starting point"
    notes: "Add AFTER rest phase. Soy sauce first for umami+salt combo"

# Phases — the execution backbone
phases:
  - id: prep
    name: "Mise en Place"
    type: active          # active = pull mode, passive = push mode
    duration: "15-20m"
    briefing: |
      We're cutting and organizing everything before heat touches anything.
      Bone-dry surfaces on the beef are critical for Maillard.
    steps:
      - instruction: "Cube the beef into 3cm pieces"
        quantity: "900g → ~30 cubes"
        technique: "Cut against visible grain lines"
        sensory_cue: "Each cube roughly the size of your thumb's first knuckle to first joint"
      - instruction: "Pat beef completely dry with paper towels"
        science: "Surface moisture → steam → no Maillard. Dry surface → browning starts at 140°C"
        sensory_cue: "Paper towel comes away without wet spots"
      - instruction: "Dice onions, 1cm pieces"
        technique: "See technique explainer if needed"
      - instruction: "Quarter mushrooms"
        technique: "Stem-down, cut through crown"

  - id: sear
    name: "Maillard Phase"
    type: active
    duration: "15-20m"
    briefing: |
      High heat, small batches, don't crowd the pan. We want mahogany
      browning on at least two faces per cube. This is where flavor is built.
    temp_target:
      surface: "210-230°C"
      sensor: ir
    steps:
      - instruction: "Heat dutch oven to 220°C surface temperature"
        sensor_check:
          type: ir
          target: "220°C"
      - instruction: "Sear beef in 2-3 batches, 90-120 seconds per face"
        batch_size: "10-12 cubes max"
        sensory_cue: "Mahogany brown crust, releases from pan without sticking"
        science: "Maillard reaction requires >140°C and dry surface. Crowding drops temp below threshold."
      - instruction: "Remove beef, sauté onions in fond"
        duration: "3-4 minutes"
        sensory_cue: "Translucent edges, fond dissolving into onion moisture"

  - id: braise
    name: "Collagen Conversion"
    type: passive           # push mode — timer driven
    duration: "90m"
    duration_range: "75-120m"
    briefing: |
      Low and slow. Collagen converts to gelatin at 80-90°C over time.
      The liquid should barely simmer — lazy bubbles, not a rolling boil.
      You can walk away. I'll check in every 15 minutes.
    temp_target:
      liquid: "88-92°C"
      sensor: tc
    sensor_schedule:
      interval: "15m"
      type: tc
      action: "Lid-lift check. What's the TC reading?"
    timer:
      duration_seconds: 5400   # 90 minutes
      label: "Braise"
    steps:
      - instruction: "Return beef to pot, add stock and mushrooms"
        scaling_note: "Liquid should cover meat by ~2cm"
      - instruction: "Bring to gentle simmer, then reduce heat"
        sensory_cue: "Lazy bubbles breaking surface every 2-3 seconds"
        science: "Target 88-92°C in liquid. Above 95°C = muscle fibers seize and toughen despite collagen converting."
        equipment_note: "Cast iron overshoots — reduce burner BEFORE reaching 90°C. Residual heat carries it up."
      - instruction: "Lid on, slight crack for steam release"

  - id: integrate-veg
    name: "Vegetable Integration"
    type: active
    duration: "25-30m"
    briefing: |
      Beef should be fork-tender. Now we add potatoes and carrots.
      They cook faster than the beef did, so timing is tighter.
    steps:
      - instruction: "Test beef tenderness"
        sensory_cue: "Fork slides in and out with zero resistance. Like warm butter."
        sensor_check:
          type: tc
          target: "90°C"
      - instruction: "Add cubed potatoes (2.5cm) and carrots (oblique cut)"
        scaling_note: "700-900g potatoes, 300g carrots"
        equipment_note: "Adding cold veg drops temp. Bump heat briefly, then reduce before it overshoots."
      - instruction: "Simmer until potatoes are tender"
        duration: "25-30 minutes"
        sensor_check:
          type: tc
          target: "90-95°C"
        sensory_cue: "Knife slides through potato center with no resistance"
    timer:
      duration_seconds: 1500   # 25 minutes
      label: "Veg Integration"

  - id: rest-season
    name: "Rest & Season"
    type: passive
    duration: "15m"
    briefing: |
      Off heat. Pressure equalizes in the meat fibers as it cools slightly.
      This is when we season — salt last, soy sauce first for umami.
    timer:
      duration_seconds: 900   # 15 minutes
      label: "Rest"
    steps:
      - instruction: "Remove from heat, lid on"
        science: "Resting lets moisture redistribute. Cutting immediately = moisture loss."
      - instruction: "After 10 minutes rest: season with soy sauce, then salt to taste"
        technique: "Soy sauce first (umami + salt), then adjust with plain salt"
        notes: "Calgary hard water — start conservative on salt"
      - instruction: "Taste and adjust"
        sensory_cue: "Should taste rich, savory, with clean salt finish"
```

## Key Conventions

### Phase Types
- `active` → Pull mode. Cook is hands-on. One instruction at a time.
- `passive` → Push mode. Timer-driven. Pre-flight briefings. Cook can leave.

### Burner Settings
Include explicit `burner` field on steps that involve heat changes. Use plain language: `"high"`, `"medium"`, `"low"`, `"medium → low"`, `"off"`. Never assume the cook knows what burner setting produces a target temperature — tell them directly.

### Sensor Checks
Always specify `target` — the **actual/true temperature**, not an instrument-adjusted reading. Calibration is applied at runtime by the cook skill, which reads `calibration.md` and presents both values to the cook: "We want X°C (about Y°C on your thermocouple)." Protocols never contain instrument-specific offsets — they stay correct even when instruments are recalibrated or replaced.

### Scaling Principles
Every ingredient carries a `scaling_principle` explaining the *why* behind the quantity. The LLM uses these to reason about scaling, not a formula engine.

### Substitution Support
Ingredients can list `substitutes` with notes on flavor/texture impact. The LLM reasons about downstream effects when substituting.

### Briefings
Every phase has a `briefing` field — delivered at phase entry and during preceding idle time as a pre-flight briefing.

### Duration vs Duration Range
`duration` is the expected time. `duration_range` is the acceptable window. The agent uses sensory cues and sensor data to decide when to actually transition, not just the clock.

### Revision History
The `revision_history` field tracks protocol evolution across cooks. Each entry records what changed, why, and which cook session motivated it.

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

The recipe skill initializes this as an empty list when creating new protocols.

**Any skill that modifies a protocol MUST append a `revision_history` entry.** This includes the debrief skill (post-cook updates), the recipe skill (refine mode), or any other skill that changes protocol values. Entries are never removed — they form an audit trail.
