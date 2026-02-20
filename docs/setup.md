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
- Temperature instruments (see below)
- Anything you *don't* have that recipes commonly assume (e.g., no stand mixer, no kitchen scale)

### Temperature instruments

Good temperature data makes the biggest difference in cooking outcomes. Two instruments cover almost everything:

- **An instant-read probe thermometer** — the kind with a metal spike you stick into food or dip into liquid. Tells you if your braise is holding at the right temperature, or if that chicken is done in the center. This is practically a must. Without one, you're guessing on doneness and food safety.
- **An infrared (IR) thermometer** — a point-and-shoot gun that reads surface temperature without touching anything. You aim it at your pan to know when it's hot enough to sear. Really nice to have for any high-heat work, but you can get by without one.

If you set up [calibration](#sensor-calibration-optional) below, the system tells you what your specific instrument should read for each target temperature.

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

If you have a probe thermometer and want to know how accurate it is, the system can calibrate it and then tell you what *your* instrument should read for each target: *"We want 90C actual — that's about 86-87C on your probe."*

This is entirely optional. If you trust your thermometer, skip it — the system works fine either way. If you're curious, run `/help` and it'll walk you through it. Takes a few minutes with ice water and boiling water.

## What if I skip this?

Pan Out works without a profile or calibration. The skills will ask more questions during cooks (because they can't assume anything about your equipment), and temperature guidance will use true targets only (no instrument-specific readings). Setting up a profile just makes everything smoother.

## Next step

[Create your first protocol →](first-recipe.html)
