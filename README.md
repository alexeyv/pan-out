# Pan Out

You want to make a proper bolognese — the kind that actually tastes like it came from a kitchen that knows what it's doing. You don't want to memorize technique details or wing it from a blog recipe. You want to understand the science, hear what to do next without looking at a screen, swap ingredients for what's actually in your fridge, and learn from each cook.

📖 **[Documentation](https://panout.org)** — setup guide, walkthroughs, and reference

Pan Out makes that practical. It's a set of AI skills for [Claude Code](https://claude.ai/claude-code) that handle the full cooking pipeline:

1. **[Research](https://panout.org/first-recipe.html)** -- deep-dive into a dish's science, techniques, and safety, then build a step-by-step protocol
2. **[Cook](https://panout.org/first-cook.html)** -- talk you through each phase at the stove with timers, temperature checks, and ingredient swaps
3. **[Debrief](https://panout.org/after-you-cook.html)** -- after you eat, capture what worked and what didn't so next time starts better

The system is built around **protocols** -- structured recipe files that hold everything needed to cook a dish: ingredients, phases, timing, temperatures, sensory cues, and the science behind each step.

## Installation

Full setup walkthrough: **[panout.org/install](https://panout.org/install.html)**

### As a Plugin (recommended)

In any Claude Code session:

```
/plugin marketplace add alexeyv/pan-out
/plugin install pan-out@pan-out-marketplace
```

Then go to the directory where you keep your cooking — the one holding `protocols/`, `sessions/` and `memory/` — and run `/panout-help`. It asks about your kitchen and writes `cook-profile.md` there, then offers to walk you through calibrating your thermometers into `calibration.md`.

Both files live in your cooking directory, not in the plugin — that is where every skill reads them from. To write them by hand instead, `references/cook-profile.example.md` and `references/calibration.example.md` show the structure. See the [kitchen setup guide](https://panout.org/setup.html) for details.

### From Source

1. Clone this repo
2. Run Claude Code with the plugin flag:
   ```
   claude --plugin-dir ./pan-out
   ```
3. From your cooking directory, run `/panout-help`. It writes `cook-profile.md` there from a short interview about your kitchen, and offers to calibrate your thermometers into `calibration.md`
4. To write those two by hand instead, copy `references/cook-profile.example.md` and `references/calibration.example.md` into that same directory as `cook-profile.md` and `calibration.md`

### Prerequisites

- [Claude Code](https://claude.ai/claude-code) v1.0.33 or later. The cook skill's passive-phase timer needs a version whose toolset includes **Monitor** and **TaskStop**; without them, cooking still works but holds fall back to a manual phone timer.
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
├── protocols/              # Cooking protocols
│   ├── {dish}.md           #   Executable protocol
│   └── {dish}-science.md   #   Companion science deep-dive
├── references/             # Shared knowledge base
│   ├── protocol-format.md  #   Protocol format specification
│   ├── food-safety.md      #   Safe cooking temperatures
│   ├── cook-profile.md     #   Your equipment & preferences (personal, gitignored)
│   └── calibration.md      #   Your thermometer offsets (personal, gitignored)
├── sessions/               # Cook session state files (gitignored)
├── memory/                 # Accumulated lessons and notes (gitignored)
├── skills/panout-cook/bin/ # Cook skill helper scripts
│   ├── hold-timer.py       #   Passive-phase timer with spoken updates
│   ├── chime.sh            #   Alert sounds (the timer calls this)
│   └── speak.sh            #   Text-to-speech (the timer calls this)
└── test/                   # Test harnesses
    └── timer/run-tests.sh  #   Hold-timer test suite
```

`hold-timer.py` expects `chime.sh` and `speak.sh` to sit beside it — it resolves them relative to its own directory, so the three move together.

## Protocols

Protocols are structured recipe files that hold the full plan for cooking a dish. The recipe skill creates them from research; you don't write them by hand. Every protocol has a companion science file (`{dish}-science.md`) that captures the chemistry, temperature rationale, failure modes, and food safety references behind the protocol's design.

## How It Works

### Hands-on vs. hands-off

- **When you're at the stove** (prep, searing) -- it talks you through the work, paced so you're never waiting on it with a pan on the heat
- **When you can walk away** (braising, resting) -- a timer runs in the background and calls you back when something needs attention

### Temperature guidance

If you have thermometers, the system reads your calibration data and tells you exactly what your instrument should show: *"We want 90C — that's about 86-87C on your probe."*

### Recipes that improve

Each cook makes the protocol better. The debrief captures timing adjustments, technique discoveries, and seasoning preferences so next time starts where this time left off.

### Memory across cooks

Lessons, equipment quirks, and calibration observations accumulate in a memory directory that every future cook reads automatically — so what you learn on one dish carries over to the next.

### Photo capture

Snap a photo mid-cook (paste or phone shortcut) and it's saved with the session. The debrief can reference what your fond or reduction actually looked like.

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

## Privacy

See the [Privacy policy](PRIVACY.md) for how Pan Out uses cooking profiles, session files, and other information you provide.
