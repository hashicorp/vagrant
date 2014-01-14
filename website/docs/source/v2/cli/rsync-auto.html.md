---
page_title: "vagrant rsync-auto - Command-Line Interface"
sidebar_current: "cli-rsyncauto"
---

# rsync-auto

**Command: `vagrant rsync-auto`**

This command watches all local directories of anj
[rsync synced folders](/v2/synced-folders/rsync.html) and automatically
initiates an rsync transfer when changes are detected. This command does
not exit until an interrupt is received.

The change detection is optimized to use platform-specific APIs to listen
for filesystem changes, and does not simply poll the directory.
