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

## Platform support

| | macOS | Linux | Windows |
|---|---|---|---|
| **Core skills** | Yes | Yes | Yes |
| **Voice output** | Yes | Yes | Screen only |
| **Dictation input** | With app | With app | With app |

Voice and dictation are optional, but they make the cooking experience much smoother — especially when your hands are busy. A dictation app like [Wispr Flow](https://wisprflow.com) lets you just say what you need.

---

{: .blue }
> ## Next step
>
> [Set up your kitchen profile →](setup.html)
