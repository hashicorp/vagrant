---
page_title: "vagrant rsync - Command-Line Interface"
sidebar_current: "cli-rsync"
---

# Rsync

**Command: `vagrant rsync`**

This command forces a resync of any
[rsync synced folders](/v2/synced-folders/rsync.html).

Note that if you change any settings within the rsync synced folders such
as exclude paths, you'll need to `vagrant reload` before this command will
pick up those changes.
