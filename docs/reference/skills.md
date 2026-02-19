---
layout: default
title: Skills
parent: Reference
nav_order: 2
---

# Skills

Pan Out is a collection of four skills that work together. Each handles a different part of the cooking pipeline.

## panout-help

**Orientation and skill routing.**

The entry point. Tell it what you want to do and it routes you to the right skill. If you're not sure where to start, start here.

Slash command: `/panout-help`

---

## panout-recipe

**Research a dish and build a protocol.**

Give it a dish name and it searches recipes, food science, and technique guides, cross-validates data from multiple sources, and builds two things: a research document (the science) and a protocol (the step-by-step plan). The process is interactive — it negotiates phase structure, technique choices, and seasoning strategy with you before committing anything.

Slash command: `/panout-recipe [dish]`. Also triggered by *"I want to make [dish]"* or *"research [dish]"*.

[Walkthrough →](../first-recipe.html)

---

## panout-cook

**Real-time guided cooking.**

The cook skill is your sous-chef — it stays one step ahead, tells you what to do next, manages timers, and checks your temperatures. One instruction at a time when you're at the stove, background updates when you can walk away. It picks up where you left off if the session restarts.

Slash command: `/panout-cook [dish]`. Also triggered by *"let's cook"* or *"start cooking"*.

[Walkthrough →](../first-cook.html)

---

## panout-debrief

**Post-cook review and learning capture.**

Closes the learning loop. It reads your cook session data, interviews you about how things went (3-5 questions, conversational), and drafts proposed changes to memory files, the protocol, and your cook profile. Nothing gets written without your approval. Every protocol update includes a revision history entry for traceability.

Slash command: `/panout-debrief`. Also triggered by *"debrief"* or *"how did that go"*.

[Walkthrough →](../after-you-cook.html)
