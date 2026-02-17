# Pan Out

AI-powered cooking companion -- research, execute, learn.

## What is this?

Pan Out is a collection of AI agent skills that turn [Claude Code](https://claude.ai/claude-code) into a kitchen companion. It handles the full cooking pipeline:

1. **Recipe Research** -- deep web research into a dish's science, techniques, and safety, compiled into an executable YAML protocol
2. **Guided Cooking** -- real-time phase-by-phase execution with voice summaries, background timers, sensor polling, and error recovery
3. **Debrief** -- post-cook review that captures lessons and refines protocols for next time

The system is built around **protocols** -- YAML "flight plans" that encode everything needed to execute a dish: ingredients, phases, timing, temperatures, sensory cues, and the science behind each step.

## Installation

### As a Plugin (recommended)

In any Claude Code session:

```
/plugin marketplace add alexeyv/pan-out
/plugin install pan-out@pan-out-marketplace
```

Then create your personal reference files:

```
cp references/cook-profile.example.md references/cook-profile.md
cp references/calibration.example.md references/calibration.md
```

Edit `references/cook-profile.md` with your equipment, preferences, and kitchen environment. If you have temperature instruments, run a boiling-water calibration and fill in `references/calibration.md`.

### From Source

1. Clone this repo
2. Run Claude Code with the plugin flag:
   ```
   claude --plugin-dir ./pan-out
   ```
3. Copy and customize your personal reference files:
   ```
   cp references/cook-profile.example.md references/cook-profile.md
   cp references/calibration.example.md references/calibration.md
   ```
4. Edit `references/cook-profile.md` with your equipment, preferences, and kitchen environment
5. If you have temperature instruments, run a boiling-water calibration and fill in `references/calibration.md`

### Prerequisites

- [Claude Code](https://claude.ai/claude-code) CLI v1.0.33+
- macOS (for TTS via `say`) or Linux with `espeak`
- Optional: thermocouple and/or IR thermometer

### Usage

- Say **"help"** to get oriented
- Say **"recipe [dish]"** to research a dish and create a protocol
- Say **"let's cook [dish]"** to execute a protocol with real-time guidance
- Say **"debrief"** after cooking to capture lessons

## Project Structure

```
pan-out/
├── skills/                 # AI agent skill definitions
│   ├── cook/               #   Real-time guided cooking
│   ├── recipe/             #   Research and protocol creation
│   ├── debrief/            #   Post-cook review and learning
│   └── help/               #   Orientation and skill routing
├── protocols/              # YAML cooking protocols
├── references/             # Shared knowledge base
│   ├── protocol-format.md  #   Protocol schema specification
│   ├── food-safety.md      #   USDA/FDA temperature minimums
│   ├── cook-profile.md     #   Your equipment & preferences (personal, gitignored)
│   └── calibration.md      #   Your sensor offsets (personal, gitignored)
├── sessions/               # Cook session state files (gitignored)
├── memory/                 # Accumulated lessons and notes (gitignored)
├── bin/                    # Utility scripts
│   └── progress-timer.sh   #   Background timer with TTS announcements
└── test/                   # Test harnesses
```

## Protocols

Protocols are YAML flight plans for cooking. See [references/protocol-format.md](references/protocol-format.md) for the full specification.

Example protocols included:
- **beef-stew.yaml** -- collagen braise with Maillard sear (~3h)
- **bolognese.yaml** -- classic Ragu alla Bolognese, oven-braised (~4.5h)

## How It Works

### Two Execution Modes

- **Pull mode** (active phases: prep, sear) -- one instruction at a time, waits for your confirmation before proceeding
- **Push mode** (passive phases: braise, rest) -- timer runs in background, agent pushes periodic updates, you can walk away

### Sensor-Aware

If you have temperature instruments, the skills read your calibration data and present corrected readings: *"We want 90C actual (about 86-87C on your thermocouple)."*

### Living Protocols

Each cook makes the recipe better. The debrief skill captures timing adjustments, technique discoveries, and seasoning preferences back into the protocol's revision history.

## Philosophy

- **Voice is the headline, screen is the article** -- two-sentence TTS summaries with full detail on screen
- **Science first** -- understand why, not just how
- **Sensory cues over clock time** -- "mahogany brown" matters more than "4 minutes"
- **Forward-only** -- confirmed steps are never repeated

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
