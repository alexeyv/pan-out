---
layout: default
title: Install
nav_order: 2
---

# Install Pan Out

You need [Claude Code](https://claude.ai/claude-code) v1.0.33 or later, and about two minutes.

## From the plugin marketplace (recommended)

{: .yellow }
> Open any Claude Code session and run:
>
> ```
> /plugin marketplace add alexeyv/pan-out
> /plugin install pan-out@pan-out-marketplace
> ```
>
> The first command registers the plugin source. The second installs Pan Out from it.

That's it. Now create a workspace.

## Create your cooking workspace

Pan Out keeps everything — protocols, session logs, calibration data, cook history — in a single directory on your machine. Create it wherever makes sense for you:

```
mkdir ~/cooking
cd ~/cooking
```

This directory is your **project root**. Always launch Claude Code from here:

```
claude
```

Pan Out resolves all its file paths relative to wherever you start Claude Code. Your protocols will live in `protocols/`, your session logs in `sessions/`, and so on. You don't need to create those subdirectories now — the skills create them as needed.

## From source

If you want to hack on the skills or run from a local copy:

1. Clone the repo somewhere (not inside your cooking workspace):
   ```
   git clone https://github.com/alexeyv/pan-out.git
   ```

2. Create your cooking workspace and launch Claude Code from it:
   ```
   mkdir ~/cooking
   cd ~/cooking
   claude --plugin-dir /path/to/pan-out
   ```

3. Verify it loaded — type `/panout-help` and you should see the Pan Out skill list.

## Platform support

| | macOS | Linux | Windows |
|---|---|---|---|
| **Core skills** | Yes | Yes | Yes |
| **Voice output** | Yes | Yes | Yes |
| **Dictation input** | With app | With app | With app |

Voice and dictation are optional, but they make the cooking experience much smoother — especially when your hands are busy. A dictation app like [Wispr Flow](https://wisprflow.com) lets you just say what you need.

---

{: .blue }
> ## Next step
>
> [Set up your kitchen profile →](setup.html)
