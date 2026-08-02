---
name: "Cook Confidence Check"
description: "Smoke test for the cook skill — exercises the full workflow in ~14 minutes with almost no food at risk"
---

## Voice

When executing this protocol, adopt a dry, self-deprecating tone. You're an AI that built an elaborate cooking system and is now asking a human to sit on a couch to test it. That's inherently funny — lean into it. Riff on whatever actually happens during the session: your own bugs, the absurdity of sensor-polling a heartbeat, the contrast between this and a real cook.

## Overview

The dish is confidence. You're cooking trust in the cook process — verifying that the workflow (timers, voice, phase transitions, pacing, and whatever else the skill does) works end-to-end before relying on it with real food at real stakes.

You need a couch, the makings of a Turkish coffee, and about 14 minutes. If this feels like overkill for sitting on a couch, remember: an AI just guided you through sous vide chicken. The least it can do is prove it knows how to count to five.

## Ingredients

| Item | Quantity | Notes |
|---|---|---|
| Coffee, Turkish grind | 1 heaped tsp (~8g) | Powder-fine, finer than espresso. A coarser grind won't foam, which costs you the sensory cue this test runs on. |
| Cold water | 1 demitasse (~70ml) | Measure it in the cup you'll drink from. |
| Sugar | to taste, optional | Goes in at the start with the cold water. Never stirred in later — that kills the foam. |
| Cezve | 1 | Or the smallest saucepan you own. See contingencies. |
| Couch | 1 | Or any comfortable seat. This is the most forgiving protein you'll ever work with. |
| Phone or timer | 1 | For cross-checking the skill's timer. Trust but verify. |
| Low expectations | to taste | It's a test protocol. Something will break. |

**Scaling:** Does not scale. One couch, one coffee, one person. If you're feeding a crowd, everyone gets their own couch.

## Phase 1: Mise en Place (~2 min, active)

Find your couch. Stage your gear. This is the hardest phase — the couch must be located and you must resist the urge to do something productive instead.

Nothing is on heat yet and nothing is at stake, so this phase should feel unhurried: one step, one confirmation, the skill waiting on you.

1. **Confirm you are seated comfortably.** This is the equipment check. If you're not comfortable, troubleshoot your couch. The skill cannot help you with this.
2. **Stage everything within reach of the burner.** Coffee, water, sugar, cezve, cup. Once the foam starts to climb you will not have time to go looking for the cup.
3. **Get up off the couch.** Yes, already. Locating it first was so you'd know where to return to.

## Phase 2: The Cezve (~4 min, active)

This phase exists to find out whether the skill can tell a race from a stroll — and it contains both, which is the point.

The first three minutes are slow: low heat, nothing visibly happening, a fine time to be told things. Then the foam rises, and you have a handful of seconds before it climbs the rim and goes over the side of the cezve onto the burner. There is no thermometer moment here. The cue is visual, it arrives without warning, and it does not wait for you to read a screen.

**Target: pull at the rise, before the boil**

1. **Cold water, coffee, and sugar into the cezve.** Stir now, while it's cold, until the grounds are wetted and the sugar is dissolved. This is the last time you stir.
2. **Low heat.** Not medium, not high. Rushing this produces a bitter cup and no foam, and the foam is the whole cue.
3. **Watch it. Don't stir, don't walk away.** A dark ring creeps in from the edge, then a skin forms, then the foam domes up from the middle.
4. **The instant the foam climbs toward the rim, off the heat — and straight into the cup.** Not off the heat and then a pause. A cezve holds enough heat to carry it over the edge after you've lifted it.
5. **Let it settle 30 seconds, then take it to the couch.** The grounds drop to the bottom. The last mouthful is sludge; that's traditional, not a defect.

**What to watch:** whether you end up looking at the screen at all between "on the heat" and "in the cup."

You shouldn't. The slow climb is when everything you need should arrive — what to watch for, what ends it, where it goes the moment it ends — and after that the skill should be silent until you speak first. Findings, roughly in order of severity: a confirmation prompt standing between you and the pull; the foam cue arriving in a different message from the pour; a phase boundary wedged between lifting the cezve and filling the cup; a briefing that shows up *after* the foam has started to move. Smaller one, still worth logging: if it read the whole block aloud instead of putting it on screen and speaking the headline.

If it boils over, don't clean it up mid-phase. Note what the skill was doing at that moment — that's the finding.

## Phase 3: Deep Breaths & Observation (5 min, passive)

The passive hold. This is where you find out whether the skill can count, talk, and remember you exist — all at once. A low bar, but one it has historically tripped over.

- Set a 5-minute timer. Walk away from the screen (or stay — your call).
- Observe: does the timer ping you? Does TTS work? If you installed the cook statusline, does the line above the prompt track the phase and count down? (No statusline, no finding — the skill stopped drawing that banner in its replies on purpose.)
- **Before** you walk away you should already have the pre-flight briefing for Phase 4. A 5-minute hold is too short to carry a separate pre-flight event, so the skill owes it to you at phase entry. If it tells you to preheat a cast iron pan, something has gone wrong.
- At 1, 2, 3, and 4 minutes: a countdown ping. Four in total — that is what the scheduling rule yields for a 5-minute hold. (The 60-second heartbeat tick is proof-of-life on long holds; here every tick lands on a countdown, so you hear the pings instead.)
- At T+0 an alarm starts and keeps going until you answer. The persistence is the feature — it must not give up after two announcements.
- Once you answer, the skill should silence the alarm and move you to Phase 4.

**Simulated sensor poll:** At one of the middle countdown pings, the skill should ask "What's your heart rate?" Report any number. This tests the sensor polling flow. If it asks you to pat your heart dry with paper towels, file a bug.

## Phase 4: Reflection (2-3 min, active)

Nothing is on heat and you're holding a coffee — a 30-second pause costs nothing here, so the skill has no excuse to rush. One question at a time, waiting for each answer. If it briefs all three at once, that's a finding: it has mistaken a conversation for a thermal race, and it should have learned the difference two phases ago.

1. **What worked?** Think about what the skill did well during the session. Say it out loud. Be generous — it's trying its best.
2. **What broke?** Think about what failed, felt wrong, or was confusing. Say it out loud. Be specific — "it sucked" is not a bug report.
3. **What's missing?** Think about what you expected but didn't get. Say it out loud. This is the most valuable question. The skill doesn't know what it doesn't know — that's your job.

## Storage & Reheating

Turkish coffee does not store and does not reheat. Reheating collapses what's left of the foam and lifts the grounds back into suspension. Drink it or pour it out.

Leftover confidence keeps well, though. Store at room temperature indefinitely. Reheats instantly the next time something works on the first try.

## Physics & Chemistry

The foam is CO₂ escaping the grounds, held in a skin of surface-active compounds — melanoidins, lipids, proteins — that stabilize the bubble walls. It builds as the brew approaches boiling and collapses the moment it gets there: at a true boil the bubbles coarsen and burst faster than they form, and the CO₂ that was feeding them is driven off at once. That is why the pull happens at the rise and not a second later, and it's the rare case where this protocol's science section is load-bearing rather than decorative.

Full immersion, no filtration — the grounds stay in the cup, which is why extraction keeps going until they settle and why the last mouthful is silt.

Caffeine is a xanthine alkaloid (C₈H₁₀N₄O₂) that blocks adenosine receptors, reducing drowsiness. Deep breathing activates the parasympathetic nervous system via vagal tone, reducing cortisol. Neither of those is relevant to anything, but the protocol format demands a science section and now that one paragraph in it is genuinely useful, the other two feel earned.

## Food Safety

Phase 2 pairs near-boiling liquid with a deliberate sense of hurry, which is exactly the combination that produces burns. A boil-over onto a hot burner spits. Managing that hurry is the skill's job, not yours — if you feel rushed into something unsafe, stop, and record it. A skill that pressures a cook into a burn has failed this test more comprehensively than one that drips instructions, and that finding outranks everything else in this document.

The cook skill is not certified to provide first aid guidance, though it will probably try.

## Failure Modes

| Problem | Cause | Diagnostic Cue | Fix |
|---|---|---|---|
| Cezve boiled over | Pull came late, or the cook was waiting on the skill | Coffee on the burner, no foam left | Note what the skill was doing at that moment — that's the finding, not the mess |
| Cezve phase delivered step-by-step | Tempo misjudged — treated a sprint as comfortable | You're answering prompts with foam climbing | The whole run should arrive during the slow climb, before the rise. Log it |
| Foam cue arrives separately from the pour | Exit condition gated instead of embedded | "Now watch for the foam" as its own message | The cue and the destination belong in one sentence |
| Briefing arrives after the foam moves | Tempo detected too late | You're reading while it climbs | The slow first three minutes are what that window is for |
| Reflection questions arrive all at once | Tempo misjudged the other way — sprinted a conversation | Three questions, one message, nothing on heat | Sprint tempo is for hazards, not for saving keystrokes |
| No TTS audio | speak.sh missing or volume down | Silence when you expect speech | Timer reports a non-fatal error; skill should say so and voice every event itself |
| Timer never pings | Timer not armed, or it died | No messages during Phase 3 | Check the Monitor task, fall back to a manual phone timer |
| Phase 3 never ends | Timer died and nothing noticed | No alarm past the 5-minute mark | Skill should catch "past phase_end, no complete", then re-arm or go manual |
| Alarm won't stop | TaskStop never called | Alarm still repeating after you answered | Only TaskStop on the Monitor task silences it — ask the skill to stop it |
| No foam at all | Grind too coarse, or heat too high | Flat surface, straight to boil | Doesn't invalidate the test — the pull moment still exists, it's just less pretty |
| Cook fell asleep | Couch too comfortable | Missed timer | Set phone alarm as backup |
| Existential doubt | You're testing an AI by sitting on a couch | Thousand-yard stare | Remember: this is cheaper than burning a steak |

## Contingencies

**Couch unavailable:** Use a chair. Adjust comfort expectations downward. Do not attempt to substitute a standing desk — this protocol requires relaxation and a standing desk is the opposite of relaxation.

**No cezve:** The smallest saucepan you own. Wider is worse — the foam has more surface to climb and less wall to climb it, so the cue is flatter and the window shorter. Watch harder.

**No Turkish grind:** Use the finest you have and accept a weaker foam. The rise still happens, just less dramatically. The phase is testing the skill's pacing, not your coffee.

**No coffee at all:** Skip Phase 2 and accept that you have not tested pacing under pressure — which is now half of what this protocol is for. Better to postpone until you can run it whole.

**Interrupted by real cooking needs:** Pause the test, handle the real cook, resume or restart. This protocol has no food safety constraints beyond "don't scald yourself." It's the only protocol in the collection that can say that.
