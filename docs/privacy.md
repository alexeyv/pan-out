---
layout: default
title: Privacy
nav_order: 7
---

# Privacy

Last updated: October 4, 2026.

**I do not collect any data from users' computers through Pan Out: no personal data, no telemetry, no analytics, and no usage reports.** Pan Out does not send your cooking files or conversations to me. They are stored in local files in your cooking workspace and read by Claude, not by me.

Pan Out is an open-source cooking plugin for Claude. It has no Pan Out account system or hosted storage service. There is no data collection endpoint operated by me in the plugin.

## Information used

Pan Out reads and writes files in your cooking workspace to personalize guidance and learn from previous cooks. These include your cook profile (equipment, preferences, dietary needs, and household details), recipes, calibration data, cooking session notes, and accumulated lessons. It may also read cooking conversation logs and photos you provide. These can contain names or other personal information you choose to include. Names, email addresses, and postal addresses are not required to use the plugin.

## Storage and processing

Pan Out's workspace files are stored in the filesystem of the environment where you run Claude. **I do not receive, access, or store these files.** Pan Out does not upload them to me or to any service I operate.

When Claude reads these files or you share information in a conversation, that content may be sent to and processed by the AI provider running your session. Your provider's privacy policy, account settings, and retention rules apply. Research searches may also send search queries to the search provider. Local file storage does not mean that AI processing stays on your device.

If you sync, back up, publish, or commit your workspace, those services or recipients may receive the files you include. Information you voluntarily post in public GitHub issues or contributions is public.

## Your control

You can inspect, edit, or delete your workspace files, including `cook-profile.md`, `sessions/`, `memory/`, and any photos or sensor logs you have saved. Deleting workspace files does not delete copies in conversation history, backups, or other services; manage those separately using their controls. Uninstalling the plugin does not automatically delete your cooking workspace.

Provide only the personal information you want Claude to use. Avoid putting credentials or unnecessary identifying details in cooking files.

## Contact

For privacy questions, email [alexey.verkhovsky@gmail.com](mailto:alexey.verkhovsky@gmail.com).
