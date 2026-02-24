# Protocol Principles

Authoring principles for protocols, learned from actual cooks. Not theory — each entry traces to a specific session where it mattered.

---

## Equipment lists must be exhaustive

Every item referenced in any step must appear in the `equipment:` front matter. If a step says "use a large spoon to baste," the spoon must be in the list. If the rest phase needs a cutting board, the board must be in the list.

The equipment list is the pre-flight checklist. Missing items mean the cook discovers mid-step that they need something they didn't stage.

*Learned: 2026-02-23 ribeye — basting spoon and large cutting board both needed but absent from the equipment list.*

## Time-critical exits include the physical destination

When a step has a time-sensitive exit (pull protein off heat, remove from oven, drain pasta), the destination — board, rack, ice bath, plate — must be part of the same instruction. Not "pull off heat" as one step and "transfer to board" as another.

Every second the protein stays in contact with a hot surface, carryover continues. A phase gate or confirmation wait between "pull" and "move to board" is dead time the cook can't afford.

*Learned: 2026-02-23 ribeye — steak sat in the hot pan off-burner for ~2 minutes during a phase transition. Residual pan heat drove internal temp from 57°C to 72°C. The pull instruction and the board transfer must be one atomic action.*

## Account for home kitchen infrastructure

Protocol research often comes from professional sources that assume instant hot water (kettle always near boiling), multiple free burners, sheet pans pre-staged in ovens, and counter space cleared for service. Home kitchens have none of this by default.

When a protocol step needs hot water, a free burner, or clear workspace, the pre-flight briefing for that phase must stage it explicitly. "Boil kettle" is a 1-2 minute task that blocks the pan sauce if it wasn't started during rest.

*Learned: 2026-02-23 ribeye — pan sauce phase needed hot water to dissolve a stock cube. Kettle wasn't staged during rest. The delay was small but avoidable, and in a tighter cook it could have cost the fond.*

## Multi-serving protocols must specify batch sizes for high-heat steps

A sear step that says "sear the chicken" for a 4-serving protocol will fail at the stove. High-heat steps (sear, sauté) have pan capacity limits. The protocol must specify: how many pieces per batch, how to hold finished batches (warm oven, tented foil, etc.), and whether timing changes across batches (first batch builds fond, last batch gets the best crust).

*Learned: sous vide chicken protocol review — adversarial review caught that the sear phase had no batch management for multi-serving cooks. A cook scaling to 4 breasts would crowd the pan, kill the Maillard reaction, and steam instead of sear.*

## Every phase needs a contingency for its most likely failure

Don't try to cover everything — just the one failure mode most likely to happen in that phase. Sear → smoke/burning recovery. Braise → liquid drops too low. Pasteurization → undertemp detection. Pan sauce → broken emulsion.

The contingency must be inline in the phase, not in a separate troubleshooting appendix. When things go wrong, the cook is not going to scroll to the bottom of the document.

*Learned: sous vide chicken protocol review — no contingency steps existed. The adversarial review added them retroactively, but they should have been there from the start.*

## Sensory cues must be concrete enough for a first attempt

"Fond is mahogany" means nothing to someone who has never seen fond. "Oil is shimmering" — what does shimmering look like? Sensory cues need enough physical description that a first-timer can recognize them without prior experience.

Good: "The fond (brown residue stuck to the pan) should be the color of dark caramel — amber to deep brown, not black."
Bad: "Deglaze when the fond is ready."

*Learned: sous vide chicken protocol review — first-cook completeness audit found multiple sensory cues that assumed prior experience the cook didn't have.*

## Every passive phase must have a timer

If a passive phase (braise, rest, sous vide hold, marinate) doesn't specify a duration in the protocol's front matter (`timer_seconds`), the cook skill cannot set a timer or alert the cook when the phase ends. The cook is left guessing or watching the clock manually.

Every passive phase gets a timer. If the duration is genuinely variable (e.g., "braise until fork-tender"), specify a range with a check interval: `timer_seconds: 5400` with a note to check at 60 and 75 minutes.

*Learned: sous vide chicken protocol — passive hold phase needed explicit timer_seconds for the kicker agent to schedule countdown pings and the ready check. Without it, the cook skill had no anchor for phase timing.*
