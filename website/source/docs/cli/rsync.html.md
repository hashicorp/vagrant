---
layout: "docs"
page_title: "vagrant rsync - Command-Line Interface"
sidebar_current: "cli-rsync"
description: |-
  The "vagrant rsync" command forces a re-sync of any rsync synced folders.
---

# Rsync

**Command: `vagrant rsync`**

This command forces a re-sync of any
[rsync synced folders](/docs/synced-folders/rsync.html).

Note that if you change any settings within the rsync synced folders such
as exclude paths, you will need to `vagrant reload` before this command will
pick up those changes.
