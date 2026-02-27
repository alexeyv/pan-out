---
layout: default
title: Kitchen Setup
nav_order: 3
---

# Set up your kitchen profile

The system needs to know what's in your kitchen. Not everything — just enough to give you advice that actually works with what you have.

## The guided way

From your cooking workspace, run:

```
/panout-help
```

If you don't have a cook profile yet, the skill detects that and walks you through setup conversationally — it asks about your kitchen, your equipment, how you like to cook, and writes the profile for you. If you mention a thermometer, it'll offer to calibrate it too (ice water, boiling water, a few minutes).

You don't need to prepare anything or know what it's going to ask. Just answer naturally and it fills in the rest.

## What it's learning about you

Here's what the profile captures and why:

- **Equipment** — your stovetop type, cookware, thermometers. The skills use this to tailor instructions ("heat your dutch oven" instead of a generic description), flag size mismatches before you start, and adjust technique for your specific materials.
- **Temperature instruments** — a probe thermometer is the single most useful tool for guided cooking. Protocols are built around internal and surface temperatures. An infrared gun is a nice bonus for high-heat searing. Without either, the skills fall back to time-only heuristics.
- **Preferences** — weeknight speed vs. all-day projects, how much science you want in your guidance, seasoning habits, dietary considerations.
- **Household** — typical serving count (recipes scale to match) and any household-wide dietary restrictions.
- **Environment** — altitude shifts boiling points and every time-temperature relationship that depends on them. Water hardness affects seasoning and some reactions.

## It's all plain text

The profile lives in `cook-profile.md` at your workspace root. Calibration data, if you set it up, lives in `calibration.md`. Both are readable Markdown files — open them in any editor to review, tweak, or rewrite anything the guided setup produced. The skills just read whatever's in the file.

## What if I skip this?

Pan Out works without a profile or calibration. The skills will ask more questions during cooks (because they can't assume anything about your equipment), and temperature guidance will use true targets only (no instrument-specific readings). Setting up a profile just makes everything smoother.

---

{: .blue }
> ## Next step
>
> [Create your first protocol →](first-recipe.html)
