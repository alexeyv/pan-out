# Contributing

## Protocols

The most valuable contributions are new cooking protocols. See [references/protocol-format.md](references/protocol-format.md) for the specification.

### Adding a Protocol

1. Fork the repo
2. Use the recipe skill (`/recipe [dish]`) or write YAML by hand following the spec
3. Review the protocol for accuracy and completeness
4. Remove any personal references (names, locations, equipment-specific calibration data)
5. Test the protocol at least once by cooking with it
6. Submit a PR

### Protocol Guidelines

- All temperatures must be **actual/true values**, not instrument-adjusted
- Include **sensory cues** alongside timed steps -- what should the cook see, smell, hear, feel?
- Follow food safety minimums from [references/food-safety.md](references/food-safety.md)
- Include **scaling principles** for each ingredient explaining *why* quantities scale
- Mark phases as `active` (hands-on) or `passive` (timer-driven)
- Include a `science` field on critical steps explaining the underlying mechanism

## Skills

If you want to improve the agent skills:

1. Read the existing skill definition in `skills/[name]/SKILL.md`
2. Test changes using the harnesses in `test/`
3. Respect the voice discipline: 2-sentence TTS max, full detail on screen
4. Keep the pull/push mode distinction -- don't flood the cook with instructions during passive phases

## Bug Reports

Open an issue with:
- What you were doing (which skill, which protocol)
- What happened vs. what you expected
- Your environment (OS, Claude Code version)

## Code of Conduct

See [.github/CODE_OF_CONDUCT.md](.github/CODE_OF_CONDUCT.md).
