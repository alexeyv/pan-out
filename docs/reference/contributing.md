---
layout: default
title: Contributing
parent: Reference
nav_order: 3
---

# Contributing

The most valuable thing you can contribute is a protocol that you've actually cooked with.

## Submit a protocol

1. Fork the [repo](https://github.com/alexeyv/pan-out)
2. Create the protocol — use the recipe skill (`recipe [dish]`) or write YAML by hand following the [protocol format](protocols.html)
3. Cook with it at least once and refine based on the results
4. Clean it up:
   - Remove personal references (names, locations, equipment-specific calibration data)
   - All temperatures must be **actual/true values**, not instrument-adjusted
   - Every ingredient needs a `scaling_principle`
   - Every active-phase step needs a `sensory_cue`
   - Every passive phase needs a `timer`
   - Include `science` fields on critical steps
5. Submit a pull request

### What makes a good protocol

- **Sensory cues over clock time** — "mahogany brown crust" is more useful than "sear for 4 minutes"
- **Science where it matters** — explain *why* on the steps where understanding the mechanism prevents mistakes
- **Explicit burner settings** — never assume the cook knows what burner setting produces a target temperature
- **Food safety compliance** — all protein temperatures must meet [USDA/FDA minimums](https://www.fsis.usda.gov/food-safety/safe-food-handling-and-preparation/food-safety-basics/safe-minimum-internal-temperature-chart)
- **Phase types that match the work** — `active` for hands-on, `passive` for timer-driven. Don't mark a braise as active.

## Improve the skills

If you want to work on the agent skills themselves:

1. Read the skill definition in `skills/[name]/SKILL.md` and `skills/[name]/instructions.md`
2. Test your changes by actually cooking with them
3. Respect the voice discipline: two-sentence TTS max, full detail on screen
4. Maintain the pull/push mode distinction — don't flood the cook with instructions during passive phases

## Report a bug

Open an issue with:
- What you were doing (which skill, which protocol)
- What happened vs. what you expected
- Your environment (OS, Claude Code version)

## Code of conduct

Be helpful, be kind, and remember that people are trusting this system while handling hot oil and sharp knives. Accuracy matters.
