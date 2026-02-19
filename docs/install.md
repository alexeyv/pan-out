---
layout: default
title: Install
nav_order: 2
---

# Install Pan Out

You need [Claude Code](https://claude.ai/claude-code) and about two minutes.

## From the plugin marketplace (recommended)

Open any Claude Code session and run:

```
/plugin marketplace add alexeyv/pan-out
/plugin install pan-out@pan-out-marketplace
```

That's it. Type `/panout-help` and tell it what you want to make — it'll figure out whether you need to research a new protocol or you're ready to cook one you already have.

## From source

If you want to hack on the skills or run from a local copy:

1. Clone the repo:
   ```
   git clone https://github.com/alexeyv/pan-out.git
   ```

2. Launch Claude Code with the plugin flag:
   ```
   claude --plugin-dir ./pan-out
   ```

3. Verify it loaded — type `/panout-help` and you should see the Pan Out skill list.

## What you need

- **[Claude Code](https://claude.ai/claude-code)** v1.0.33 or later
- **A dictation app** like [Wispr Flow](https://wisprflow.com) — strongly recommended. Typing mid-cook is slow and distracting; dictation lets you wipe your hands, hold a button, say what you need, and let go — much faster than typing.

Works on macOS, Linux, and Windows. Voice output (Pan Out talking back to you) is currently macOS and Linux only — on Windows you'll read instructions on screen instead. Both dictation and voice are optional, but they make the cooking experience much smoother.

### Temperature instruments

- **An instant-read probe thermometer** — the kind with a metal spike you stick into food or dip into liquid. Tells you if your braise is holding at the right temperature, or if that chicken is done in the center. This is practically a must. Without one, you're guessing on doneness and food safety.
- **An infrared (IR) thermometer** — a point-and-shoot gun that reads surface temperature without touching anything. You aim it at your pan to know when it's hot enough to sear. Really nice to have for any high-heat work, but you can get by without one.

The system works with whatever you have — if you set up [calibration](setup.html), it even tells you what your specific instrument should read for each target temperature.

## Next step

[Set up your kitchen profile →](setup.html)
