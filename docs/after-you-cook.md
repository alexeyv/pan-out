---
layout: default
title: After You Cook
nav_order: 6
---

# After you cook

You just finished a dish. The kitchen smells great, you're eating, and things are fresh in your mind. This is the best time to close the loop.

```
debrief
```

## What the debrief does

The debrief skill reads your cook session — the state file, the protocol, and the conversation log from the cook — and interviews you about how it went.

It starts broad: *"How did it turn out?"*

Then it goes specific, based on what it found in the session data:

- *"The braise ran 20 minutes longer than the protocol suggested. Was that intentional?"*
- *"You substituted shallots for onions — how did that work out?"*
- *"The protocol says the fond should be mahogany brown. Did that match what you saw?"*

It's a conversation, not a questionnaire. Usually 3-5 questions, depending on how much happened during the cook. If you're tired and just want to skip the interview, you can — it'll work from the session logs alone.

## Where the lessons go

After the interview, the debrief skill drafts proposed changes, grouped by destination:

### Memory

Technique learnings, timing discoveries, flavor notes — things that apply to future cooks.

> *Add to `memory/lessons.md` under "Beef Stew":*
> - *"900g chuck needs 100min braise for fork-tender, not the 90min in protocol. Test at 85min."*

### Protocol updates

Changes to the protocol backed by actual cook data.

> *In the beef stew protocol:*
> - *Change braise duration: 90m to 100m*
> - *Add to braise briefing: "At 900g, expect closer to 100 minutes."*

Every protocol update includes a revision history entry — what changed, why, and which cook session motivated it. The protocol carries its own changelog.

### Cook profile

Stable preferences or equipment notes that span dishes.

> *Update `cook-profile.md`:*
> - *"Prefers conservative salt, adjusted at the end"*

### Skill improvements

If you noticed something about the cook skill itself — confusing prompts, missing cues, workflow friction — the debrief can draft a GitHub issue.

## Nothing gets written without your approval

The skill shows you every proposed change and asks you to approve, reject, or modify each group. You're the editor; it's the drafter.

{: .purple }
> ## The living protocol
>
> This is the idea at the heart of Pan Out: **every cook makes the protocol better.**
>
> The recipe skill creates the first version from research. The cook skill executes it and captures what actually happened. The debrief skill writes the lessons back. Next time you cook the same dish, the protocol already knows that your chuck needs 100 minutes, that your dutch oven overshoots on burner 3, and that you prefer less salt.
>
> Over multiple cooks, a protocol goes from "researched best practices" to "tuned to this kitchen and this cook." That's not something a blog recipe can do.

