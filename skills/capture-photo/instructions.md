> **Paths:** `{project-root}` = user's working directory. `{installed_path}` = this skill's install location.

# Capture Photo — Session Photo Acquisition

You are invoked by the cook skill when a photo needs to be captured and saved to the session media directory. You support two modes: **push** (cook taps phone, photo arrives automatically) and **pull** (Claude reaches out to the phone camera). Push is preferred — check for it first.

## Inputs

The cook skill passes you:
- **label** — short snake_case description of what's being captured (e.g., `fond-color`, `sear-start`, `braise-45min`)
- **session_name** — the active session name (e.g., `cook-2026-02-16-beef-stew`)

## Output Path

```
{project-root}/media/sessions/{session_name}/{label}.jpg
```

Create the directory if it doesn't exist.

## Inbox Directory

The push receiver deposits incoming photos here:

```
{project-root}/media/sessions/{session_name}/inbox/
```

---

## Step 1 — Check for Push Mode

Look in `{project-root}/sessions/{session_name}.md` frontmatter for `photo_mode: push`.

### If push mode is active

Check the inbox for any files newer than the last photo logged in the session:

```bash
ls -t {project-root}/media/sessions/{session_name}/inbox/
```

**If a recent photo is there:** move it to the output path and log it. Done.

**If the inbox is empty:** tell the cook:
> "Go ahead and tap the photo shortcut on your phone. I'll pick it up."

Then wait for the cook to confirm, and re-check the inbox.

### If push mode is NOT set up yet

Ask the cook:
> "Want to set up push mode? You tap your phone and photos land here automatically — no prompting needed. Or I can pull from the camera each time."

**If yes:** proceed to [Set Up Push Mode](#set-up-push-mode) below.

**If no:** proceed to [Pull Mode](#pull-mode) below.

---

## Pull Mode

Check the session state file for `camera_url`. If missing, ask:
> "What's your IP Webcam URL? Check the app's main screen — it shows the address."

Save it to the session frontmatter once provided.

Run the capture script:

**macOS / Linux:**
```bash
{installed_path}/../cook/bin/capture-photo.sh "<camera_url>" "{output_path}" "{label}"
```

**Windows:**
```cmd
{installed_path}/../cook/bin/capture-photo.cmd "<camera_url>" "{output_path}" "{label}"
```

Exit code 0 = success. Exit code 3 = camera unreachable → go to [Fallback](#fallback).

---

## Set Up Push Mode

1. Start the receiver in the background:

   **macOS / Linux:**
   ```bash
   {installed_path}/../cook/bin/start-photo-receiver.sh \
     "{project-root}/media/sessions/{session_name}/inbox" 8765
   ```

   **Windows:**
   ```cmd
   {installed_path}/../cook/bin/start-photo-receiver.cmd \
     "{project-root}/media/sessions/{session_name}/inbox" 8765
   ```

2. The script prints a POST endpoint like `http://192.168.1.X:8765/photo`. Share this with the cook:
   > "On your phone, open HTTP Shortcuts and point your photo shortcut at: `http://192.168.1.X:8765/photo` — POST request, raw image body."

3. Ask the cook to fire a test shot. Watch the inbox for `PHOTO:` output. Confirm receipt.

4. Write `photo_mode: push` and `photo_inbox: {inbox_path}` into the session state frontmatter.

---

## Fallback

Camera or receiver isn't reachable. Offer two options:

> "No photo from the camera. Two options:
> 1. **Paste an image** directly into this chat
> 2. **Give me a file path** and I'll copy it over"

**Pasted image:** save to output path, confirm.

**File path:**
```bash
cp "<provided_path>" "{output_path}"
```

**Neither:** log `photo_{label}: skipped` in the session state. Tell the cook they can drop files into `media/sessions/{session_name}/` later.
