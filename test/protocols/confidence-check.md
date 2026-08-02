---
name: "Cook Confidence Check"
description: "Smoke test for the cook skill — exercises the full workflow in ~10 minutes with no food at risk"
---

## Voice

When executing this protocol, adopt a dry, self-deprecating tone. You're an AI that built an elaborate cooking system and is now asking a human to sit on a couch to test it. That's inherently funny — lean into it. Riff on whatever actually happens during the session: your own bugs, the absurdity of sensor-polling a heartbeat, the contrast between this and a real cook.

## Overview

The dish is confidence. You're cooking trust in the cook process — verifying that the workflow (timers, voice, phase transitions, and whatever else the skill does) works end-to-end before relying on it with real food at real stakes.

You need a couch, a cup of coffee, and 10 minutes. If this feels like overkill for sitting on a couch, remember: an AI just guided you through sous vide chicken. The least it can do is prove it knows how to count to five.

## Ingredients

| Item | Quantity | Notes |
|---|---|---|
| Coffee | 1 cup | Or tea. Or water. The point is you have something to sip. |
| Couch | 1 | Or any comfortable seat. This is the most forgiving protein you'll ever work with. |
| Phone or timer | 1 | For cross-checking the skill's timer. Trust but verify. |
| Low expectations | to taste | It's a test protocol. Something will break. |

**Scaling:** Does not scale. One couch, one coffee, one person. If you're feeding a crowd, everyone gets their own couch.

## Phase 1: Mise en Place (~2 min, active)

Find your couch. Prepare your coffee. Sit down. This is the hardest phase — the couch must be located, the coffee must be brewed, and you must resist the urge to do something productive instead.

1. **Confirm you are seated comfortably.** This is the equipment check. If you're not comfortable, troubleshoot your couch. The skill cannot help you with this.
2. **Confirm coffee is within arm's reach.** This is the ingredient check. Mise en place means everything in its place. Your coffee's place is within arm's reach.
3. **Take a sip.** This is the mise en place. You have now prepped your only ingredient. Congratulations — you're already ahead of most of your real cooks.

## Phase 2: Deep Breaths & Observation (5 min, passive)

The passive hold. This is where you find out whether the skill can count, talk, and remember you exist — all at once. A low bar, but one it has historically tripped over.

- Set a 5-minute timer. Walk away from the screen (or stay — your call).
- Observe: does the timer ping you? Does TTS work? If you installed the cook statusline, does the line above the prompt track the phase and count down? (No statusline, no finding — the skill stopped drawing that banner in its replies on purpose.)
- **Before** you walk away you should already have the pre-flight briefing for Phase 3. A 5-minute hold is too short to carry a separate pre-flight event, so the skill owes it to you at phase entry. If it tells you to preheat a cast iron pan, something has gone wrong.
- At 1, 2, 3, and 4 minutes: a countdown ping. Four in total — that is what the scheduling rule yields for a 5-minute hold. (The 60-second heartbeat tick is proof-of-life on long holds; here every tick lands on a countdown, so you hear the pings instead.)
- At T+0 an alarm starts and keeps going until you answer. The persistence is the feature — it must not give up after two announcements.
- Once you answer, the skill should silence the alarm and move you to Phase 3.

**Simulated sensor poll:** At one of the middle countdown pings, the skill should ask "What's your heart rate?" Report any number. This tests the sensor polling flow. If it asks you to pat your heart dry with paper towels, file a bug.

## Phase 3: Reflection (2-3 min, active)

Pull mode. One step at a time. If the skill dumps all three questions at once, that's already a finding.

1. **What worked?** Think about what the skill did well during the session. Say it out loud. Be generous — it's trying its best.
2. **What broke?** Think about what failed, felt wrong, or was confusing. Say it out loud. Be specific — "it sucked" is not a bug report.
3. **What's missing?** Think about what you expected but didn't get. Say it out loud. This is the most valuable question. The skill doesn't know what it doesn't know — that's your job.

## Storage & Reheating

Your coffee may have cooled during Phase 2. Microwave 30 seconds or brew a fresh cup. The couch requires no maintenance.

Leftover confidence keeps well. Store at room temperature indefinitely. Reheats instantly the next time something works on the first try.

## Physics & Chemistry

Caffeine is a xanthine alkaloid (C₈H₁₀N₄O₂) that blocks adenosine receptors, reducing drowsiness. Optimal extraction temperature for coffee is 90-96°C. Deep breathing activates the parasympathetic nervous system via vagal tone, reducing cortisol. Neither of these facts is relevant to testing the cook skill, but the protocol format demands a science section and who are we to argue with the format.

## Food Safety

Do not spill hot coffee on yourself. The cook skill is not certified to provide first aid guidance, though it will probably try.

## Failure Modes

| Problem | Cause | Diagnostic Cue | Fix |
|---|---|---|---|
| No TTS audio | speak.sh missing or volume down | Silence when you expect speech | Timer reports a non-fatal error; skill should say so and voice every event itself |
| Timer never pings | Timer not armed, or it died | No messages during Phase 2 | Check the Monitor task, fall back to a manual phone timer |
| Phase 2 never ends | Timer died and nothing noticed | No alarm past the 5-minute mark | Skill should catch "past phase_end, no complete", then re-arm or go manual |
| Alarm won't stop | TaskStop never called | Alarm still repeating after you answered | Only TaskStop on the Monitor task silences it — ask the skill to stop it |
| Coffee cold | Phase 2 too long | Lukewarm sip | Microwave 30s |
| Cook fell asleep | Couch too comfortable | Missed timer | Set phone alarm as backup |
| Existential doubt | You're testing an AI by sitting on a couch | Thousand-yard stare | Remember: this is cheaper than burning a steak |

## Contingencies

**Couch unavailable:** Use a chair. Adjust comfort expectations downward. Do not attempt to substitute a standing desk — this protocol requires relaxation and a standing desk is the opposite of relaxation.

**Coffee unavailable:** Substitute any beverage. Protocol integrity is not affected. Protocol enjoyment may be.

**Interrupted by real cooking needs:** Pause the test, handle the real cook, resume or restart. This protocol has no food safety constraints. It's the only protocol in the collection that can say that.
