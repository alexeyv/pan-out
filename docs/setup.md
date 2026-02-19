---
layout: default
title: Kitchen Setup
nav_order: 3
---

# Set up your kitchen profile

The system needs to know what's in your kitchen. Not everything — just enough to give you advice that actually works with what you have.

## Create your cook profile

Copy the example file and fill it in:

```
cp references/cook-profile.example.md references/cook-profile.md
```

Open `references/cook-profile.md` in any editor. Here's what matters and why:

### Equipment

List your cookware, heat sources, and prep tools. The system uses this to:
- **Tailor instructions** — "heat your dutch oven" instead of "heat a large heavy-bottomed pot (ideally enameled cast iron)"
- **Flag conflicts** — if a protocol needs a 5L dutch oven and you have a 3L, it'll tell you before you start
- **Adjust technique** — cast iron holds heat differently than stainless; induction behaves differently than gas

You don't need to catalog every spatula. Focus on:
- Oven and stovetop type (gas, electric, induction)
- Dutch ovens and large pots — size and material
- Temperature instruments (thermocouple, IR gun, probe thermometer)
- Anything you *don't* have that recipes commonly assume (e.g., no stand mixer, no kitchen scale)

### Preferences

How do you like to cook?

- **Approach** — are you optimizing for weeknight speed, or will you spend all Saturday on a braise?
- **Science level** — do you want the full chemistry explanation, or just tell you what to do?
- **Seasoning habits** — salt early? Salt late? Heavy hand or conservative?
- **Dietary considerations** — restrictions, preferences, things you avoid

### Household

- Typical serving count (the system scales recipes to match)
- Dietary restrictions that apply to the whole household

### Environment

- **Altitude** — this matters more than you'd think. Water boils at 97C at 1000m elevation, which shifts every time-temperature relationship in the book.
- **Water hardness** — affects seasoning and some chemical reactions

## Sensor calibration (optional)

If you have a thermocouple or IR thermometer, calibration makes the system dramatically more useful. Without it, the system gives you true target temperatures. With it, it says: *"We want 90C actual — that's about 86-87C on your thermocouple."*

Copy the calibration template:

```
cp references/calibration.example.md references/calibration.md
```

### The boiling water test

1. Bring a pot of water to a rolling boil
2. Look up your altitude — boiling point drops about 1C per 300m above sea level
3. Measure the boiling water with each instrument
4. Record the difference between what the instrument shows and what the actual temperature should be

That's your offset. Fill it into `references/calibration.md`. The system applies it automatically during cooks.

A few things to know about calibration:
- Thermometer error is a **slope**, not a constant offset — it's most accurate near where you calibrated and drifts as you move away
- Offsets **change over time** — recalibrate every few months
- At high surface temps (above 200C), IR readings vary with the cookware material — cast iron is reliable, stainless less so

## What if I skip this?

Pan Out works without a profile or calibration. The skills will ask more questions during cooks (because they can't assume anything about your equipment), and temperature guidance will use true targets only (no instrument-specific readings). Setting up a profile just makes everything smoother.

## Next step

[Create your first protocol →](first-recipe.html)
