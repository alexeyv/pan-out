---
layout: default
title: First Cook
nav_order: 5
---

# Cook with Pan Out

This is the part where the screen gets splattered. You have a protocol, your ingredients are on the counter, and you're ready to go.

```
cook beef stew
```

## Before the heat goes on

The cook skill doesn't throw you straight into chopping. It runs through a startup sequence:

### Scale and substitutions

First question: *"How much are we working with?"*

Answer however makes sense — "I've got 1.2kg of chuck", "feeding 6 tonight", or "just a small batch." The skill takes whatever you give it and scales the protocol's quantities.

Then: *"Any ingredients you're missing or want to swap?"* If the protocol lists substitutes (e.g., shallots for onions), it'll mention those. If you want to swap something not on the list, it reasons about the impact and adjusts.

### Audio check

The skill tests whether voice works on your system. You'll hear *"Can you hear me?"* — confirm, and voice prompts are on for the whole session. If TTS isn't working, it falls back to chime alerts, then screen-only as a last resort.

Voice is important. When your hands are covered in raw meat and you're managing a hot pan, a two-sentence spoken summary beats scrolling through a chat window.

### Pre-flight briefing

Before each phase starts, the skill runs an aviation-style checklist:
- What this phase is about and why it matters
- Equipment you'll need ready
- Questions? *"Now's the time."*

## Two modes of cooking

The cook skill has two modes, and it switches between them automatically based on what the protocol says about each phase.

{: .blue }
> ### Pull mode — you're at the stove
>
> Active phases (prep, sear, saute) run in pull mode. The skill gives you **one instruction at a time** and waits for you to confirm before moving on.
>
> > *Voice: "Sear the first batch — 10 to 12 cubes, 90 seconds per face."*
> >
> > Screen shows the full detail: batch size, sensory cue ("mahogany brown crust, releases from pan without sticking"), the science behind why crowding kills the sear.
> >
> > You do the step, say "done" or "next."
> >
> > The skill advances. *"Step 3 of 5. Remove the beef, saute the onions in the fond."*
>
> If you ask a question mid-step — "what's an oblique cut?" — the skill answers immediately, with a full mechanical how-to, then picks up where you left off. Questions always take priority over advancing the protocol.

{: .yellow }
> ### Push mode — you can walk away
>
> Passive phases (braise, rest, marinate) run in push mode. A timer starts in the background, and the skill tells you what to expect:
>
> > *Voice: "Braise is on. Timer set for 90 minutes. You can walk away — I'll call you back for a lid-lift check."*
>
> During the hold, the skill does useful things with the dead time:
> - **Pre-flight briefing** for the next phase — what to prepare, what to have ready
> - **Science on demand** — ask "why" at any point and the skill pulls from the protocol's companion science file (`{dish}-science.md`) to explain the physics behind the step. Why collagen converts at 80-90C, why a lazy simmer beats a rolling boil.
> - **Sensor polls** at regular intervals — *"What's the thermocouple reading?"*
>
> During long holds, you'll hear periodic spoken check-ins — a brief progress update so you know it hasn't forgotten about you and the braise hasn't run away.
>
> When the timer fires, it calls you back:
>
> > *Voice: "Timer's up. Lid-lift check — grab your thermometer."*
>
> It asks for a sensor reading, evaluates whether to continue the hold or transition, and moves on when the food is ready — guided by sensory cues, not just the clock.

## Talking to it

You're cooking, not typing an essay. The skill understands natural confirmations:

- **"done"**, **"next"**, **"ready"** — advance to the next step
- **"what's an oblique cut?"** — get a technique explainer
- **"timer went off"** — skip to timer completion handling
- **"I messed up"** or **"it's burning"** — triggers error recovery
- **"what's next?"** — preview what's coming

If something goes wrong, the skill stays calm. It quantifies the consequence — *"That's maybe a 3 out of 10 on the final dish"* — so you know whether to worry or shrug, then gives you a forward path and logs the deviation so the debrief skill can learn from it.

You can also snap photos during the cook — paste an image or use a phone shortcut — and the skill saves them with the session. Useful for capturing what your fond actually looked like or how the braise reduced, and the debrief can reference them later.

## Temperatures

If you set up [sensor calibration](setup.html), temperature guidance looks like this:

> *"We want 90C actual — that's about 86-87C on your thermocouple."*

Both values, every time. The protocol stores true temperatures; the skill reads your calibration data and does the math so you never have to. Without calibration, you just see the true target.

## Session state

Every cook is tracked in a session state file (`sessions/cook-YYYY-MM-DD-dish.md`). This is automatic — you won't notice it happening. But it means:

- **Crash recovery** — if Claude Code restarts mid-cook, it can pick up where you left off
- **Debrief fuel** — the state file captures timestamps, sensor readings, deviations, and decisions, giving the debrief skill rich data to work with

## Wrapping up

When the last phase completes, the skill offers serving guidance, storage tips, and reheating instructions. Then:

> *Voice: "Nice work. That's a wrap."*

It offers to run a debrief while the cook is fresh in your mind.

## Next step

[What happens after you cook →](after-you-cook.html)
