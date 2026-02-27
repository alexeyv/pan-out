# Pan Out

You want to make a proper bolognese — the kind that actually tastes like it came from a kitchen that knows what it's doing. You don't want to memorize technique details or wing it from a blog recipe. You want to understand the science, hear what to do next without looking at a screen, swap ingredients for what's actually in your fridge, and learn from each cook.

📖 **[Documentation](https://panout.org)** — setup guide, walkthroughs, and reference

Pan Out makes that practical. It's a set of AI skills for [Claude Code](https://claude.ai/claude-code) that handle the full cooking pipeline:

1. **Research** -- deep-dive into a dish's science, techniques, and safety, then build a step-by-step protocol
2. **Cook** -- talk you through each phase at the stove with timers, temperature checks, and ingredient swaps
3. **Debrief** -- after you eat, capture what worked and what didn't so next time starts better

The system is built around **protocols** -- structured recipe files that hold everything needed to cook a dish: ingredients, phases, timing, temperatures, sensory cues, and the science behind each step.

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

- [Claude Code](https://claude.ai/claude-code) v1.0.33 or later
- An instant-read probe thermometer — for checking liquid temps, meat doneness, and food safety. Practically a must.
- An infrared (IR) thermometer — point-and-shoot surface temp readings for searing and high-heat work. Really nice to have.
- A dictation app like [Wispr Flow](https://wisprflow.com) — strongly recommended. Typing mid-cook is slow and distracting; dictation lets you wipe your hands, hold a button, say what you need, and let go — much faster than typing.

Works on macOS, Linux, and Windows, including voice output. Dictation and voice are both optional, but they make the cooking experience much smoother.

### Usage

- Run **`/panout-help`** to get oriented
- Say **"recipe [dish]"** to research a dish and create a protocol
- Say **"let's cook [dish]"** to cook a dish step by step
- Say **"debrief"** after cooking to capture lessons

## Project Structure

```
pan-out/
├── skills/                 # The skills that do the work
│   ├── cook/               #   Real-time guided cooking
│   ├── recipe/             #   Research and protocol creation
│   ├── debrief/            #   Post-cook review and learning
│   └── help/               #   Orientation and skill routing
├── protocols/              # YAML cooking protocols
├── references/             # Shared knowledge base
│   ├── protocol-format.md  #   Protocol format specification
│   ├── food-safety.md      #   Safe cooking temperatures
│   ├── cook-profile.md     #   Your equipment & preferences (personal, gitignored)
│   └── calibration.md      #   Your thermometer offsets (personal, gitignored)
├── sessions/               # Cook session state files (gitignored)
├── memory/                 # Accumulated lessons and notes (gitignored)
├── bin/                    # Utility scripts
│   └── progress-timer.sh   #   Background timer with spoken updates
└── test/                   # Test harnesses
```

## Protocols

Protocols are structured recipe files that hold the full plan for cooking a dish. See [references/protocol-format.md](references/protocol-format.md) for the format.

Example protocols included:
- **beef-stew.yaml** -- slow braise with a hard sear up front (~3h)
- **bolognese.yaml** -- classic ragu, oven-braised (~4.5h)

## How It Works

### Hands-on vs. hands-off

- **When you're at the stove** (prep, searing) -- one instruction at a time, waits for you to say "done" before moving on
- **When you can walk away** (braising, resting) -- a timer runs in the background and calls you back when something needs attention

### Temperature guidance

If you have thermometers, the system reads your calibration data and tells you exactly what your instrument should show: *"We want 90C — that's about 86-87C on your probe."*

### Recipes that improve

Each cook makes the protocol better. The debrief captures timing adjustments, technique discoveries, and seasoning preferences so next time starts where this time left off.

## Philosophy

- **Voice is the headline, screen is the article** -- short spoken summaries you can hear over kitchen noise, full detail on screen when you look
- **Science first** -- understand why, not just how
- **Sensory cues over clock time** -- "mahogany brown" matters more than "4 minutes"
- **Forward-only** -- once you confirm a step, it's done. No going back.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Acknowledgments

Pan Out's skill structure, workflow patterns, and prompt language were built with and heavily inspired by the [BMAD Method](https://github.com/bmad-code-org/BMAD-METHOD) by BMad Code, LLC ([MIT](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/LICENSE)).

## License

[MIT](LICENSE)
