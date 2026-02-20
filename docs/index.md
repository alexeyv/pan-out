---
layout: default
title: Home
nav_order: 1
---

# Your AI sous-chef, in the terminal.

<div class="terminal">
  <div class="terminal-header">
    <span class="terminal-dot red"></span>
    <span class="terminal-dot yellow"></span>
    <span class="terminal-dot green"></span>
    <span class="terminal-title">pan-out — claude code</span>
  </div>
  <div class="terminal-body">
    <span class="user-prompt">You:</span> <span class="response">I want to make beef stew</span><br>
    <span class="prompt">Pan Out:</span> <span class="response">Let me research that. What equipment do you have?</span><br>
    <span class="user-prompt">You:</span> <span class="response">Dutch oven, gas stove, instant-read thermometer</span><br>
    <span class="prompt">Pan Out:</span> <span class="response">Protocol ready — 5 phases, about 3 hours. Say "let's cook" when you're ready.</span><br>
    <span class="muted">...</span><br>
    <span class="prompt">Pan Out:</span> <span class="speaker">🔊</span> <span class="response">Sear the first batch — 10 to 12 cubes, 90 seconds per face.</span><br>
    <span class="user-prompt">You:</span> <span class="response">done</span><br>
    <span class="prompt">Pan Out:</span> <span class="speaker">🔊</span> <span class="response">Step 3 of 5. Remove the beef, sauté the onions in the fond.</span><br>
    <span class="muted">...</span><br>
    <span class="prompt">Pan Out:</span> <span class="speaker">🔊</span> <span class="response">Nice work. That's a wrap. Want to debrief while it's fresh?</span>
  </div>
</div>

You want to make a proper bolognese — the kind that actually tastes like it came from a kitchen that knows what it's doing. You know the basics, but you don't want to wing it from a blog recipe and hope for the best. You want to understand *why* the sear matters, be told (in words, not beeps!) when it's time to flip, swap out an ingredient without ruining the dish, and come out the other side knowing more than when you started.

That's what Pan Out does. It's a set of AI skills for [Claude Code](https://claude.ai/claude-code) that handle the full arc of cooking a dish:

{: .highlight }
> ## 🔬 Research it
>
> **[Build a protocol.](first-recipe.html)** You name a dish. Pan Out pulls from recipes, food science, and technique guides, cross-validates temperatures and times, and compiles everything into a step-by-step protocol tuned to your kitchen, your equipment, and your preferences.

{: .important }
> ## 🔪 Cook it
>
> **[Cook with your protocol.](first-cook.html)** Before anything hits the pan, it asks what you're working with — a kilo of chuck, half a bag of onions, feeding two or feeding ten. It adjusts the entire plan to match. Then at the stove, Pan Out becomes your sous-chef — it stays one step ahead of you, tells you what to do next, watches the timers, checks your temperatures, and tells you what to look for instead of just how long to wait. When you're braising for two hours, it tells you to walk away and calls you back when something needs attention.

{: .note }
> ## 📈 Learn from it
>
> **[Debrief and improve.](after-you-cook.html)** After you eat, a quick debrief captures what worked and what didn't. Timing adjustments, technique discoveries, seasoning preferences — all written back into the protocol so next time starts where this time left off.

The system is built around **protocols** — structured recipe files that hold everything needed to cook a dish. They're not static recipes. They're living documents that get better every time you cook.

---

Two minutes to set up. [Install Pan Out →](install.html)
