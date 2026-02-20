---
layout: default
title: First Recipe
nav_order: 4
---

# Create your first protocol

Pick a dish. Something you've made before is ideal for your first run — you'll have intuition to compare against, and you can focus on learning the system instead of learning the dish at the same time.

The skill is called "recipe" because that's what you're thinking — *I want a recipe for beef stew.* But what it builds is a **protocol**, and a protocol is a lot more than a recipe.

A recipe is a list of ingredients and steps. A protocol carries the science behind each step — *why* you sear before you braise, what temperature breaks down collagen without toughening the muscle, what "mahogany brown" actually looks like. It knows your equipment, your thermometer's quirks, your seasoning preferences. It tells you what to look for, not just how long to wait. And it gets better every time you cook it — each debrief writes lessons back into the protocol so the next cook starts smarter than the last one.

A recipe is a trail map. A protocol is a guide who's walked it before.

## Start with help

Type `/panout-help` and tell it what you want to make:

- *"I want to make chicken thighs"*
- *"let's do a risotto"*
- *"I'm thinking pan-seared salmon"*

Pan Out checks whether you already have a protocol for that dish. If you do, it routes you straight to cooking. If you don't, it starts the recipe skill to research and build one.

## Phase 1: Intake — "What are we making?"

The skill starts by understanding your context. It reads your cook profile and any existing memory, then asks a few calibration questions:

- **What's your goal?** First attempt? Refining a dish you've made before? Solving a specific problem?
- **Equipment check** — confirms what's available, or asks if it doesn't know
- **How many servings?**
- **Any constraints?** Time budget, missing ingredients, dietary needs

If you already have a protocol for this dish (from a previous run), it'll offer to refine rather than rebuild from scratch: *"You already have a beef stew protocol. Want to revise it, or start fresh?"*

If you have protocols for related dishes — say, a lamb braise when you're building a beef braise — it'll pull in proven patterns as a starting point.

## Phase 2: Research — "Understand the science"

This is where the skill does its homework. It runs multiple web searches targeting:

- **Core science** — heat transfer, protein denaturation, Maillard reaction conditions, collagen conversion
- **Authoritative technique** — detailed methods from established sources (Harold McGee, Kenji Lopez-Alt, ATK)
- **Common failure modes** — what goes wrong and why
- **Temperature and time data** — cross-validated from multiple sources
- **Food safety** — FDA/USDA guidelines for the relevant proteins
- **Your equipment** — how your specific gear affects the technique

It compiles everything into a research document and shows it to you. This is the "why" behind the dish — the science that makes the protocol make sense.

You review it, ask questions, push back. The skill won't move on until you're satisfied with the research.

## Phase 3: Protocol compilation — "Build the flight plan"

Now the skill proposes a phase structure:

> *"I'm thinking 5 phases:*
> 1. *Mise en Place — cutting, drying, organizing (15-20m)*
> 2. *Maillard Phase — high-heat sear in batches (15-20m)*
> 3. *Collagen Conversion — low-and-slow braise (90m)*
> 4. *Vegetable Integration — potatoes and carrots (25-30m)*
> 5. *Rest & Season — off heat, final seasoning (15m)*
>
> *Total time: about 3 hours. Does that match how you'd approach this?"*

This is a negotiation, not a dictation. You can merge phases, split them, change the order, adjust technique. The skill compiles your agreed structure into protocol YAML — the executable format that the cook skill consumes.

Every protocol includes:
- **Ingredients** with quantities, functional roles, scaling principles, and substitution notes
- **Phases** marked as active (hands-on) or passive (timer-driven)
- **Steps** with sensory cues, science notes, and equipment-specific guidance
- **Temperature targets** as true/actual values (calibration is applied at cook time)
- **Timers** for every passive phase

## Phase 4: Finalize — "Save and hand off"

The skill writes two files:

- `protocols/beef-stew.yaml` — the executable protocol
- `protocols/beef-stew-research.md` — the science deep-dive

Then it hands off:

> *"Protocol ready. Say 'let's cook' when you're ready to start."*

## What the protocol looks like

You don't need to read the YAML — the cook skill handles it. But if you're curious, here's a taste:

{: .highlight }
> ```yaml
> phases:
>   - id: sear
>     name: "Maillard Phase"
>     type: active
>     duration: "15-20m"
>     briefing: |
>       High heat, small batches, don't crowd the pan.
>       We want mahogany browning on at least two faces per cube.
>     steps:
>       - instruction: "Sear beef in 2-3 batches, 90-120s per face"
>         batch_size: "10-12 cubes max"
>         sensory_cue: "Mahogany brown crust, releases from pan without sticking"
>         science: "Maillard reaction requires >140C and dry surface."
> ```

For the full format specification, see [Protocol Reference](reference/protocols.html).

## Next step

[Cook with your protocol →](first-cook.html)
