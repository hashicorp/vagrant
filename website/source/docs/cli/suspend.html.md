---
layout: "docs"
page_title: "vagrant suspend - Command-Line Interface"
sidebar_current: "cli-suspend"
description: |-
  The "vagrant suspend" command is used to suspend the guest machine Vagrant is
  currently managing.
---

# Suspend

**Command: `vagrant suspend [name|id]`**

This suspends the guest machine Vagrant is managing, rather than fully
[shutting it down](/docs/cli/halt.html) or [destroying it](/docs/cli/destroy.html).

A suspend effectively saves the _exact point-in-time state_ of the machine,
so that when you [resume](/docs/cli/resume.html) it later, it begins running
immediately from that point, rather than doing a full boot.

This generally requires extra disk space to store all the contents of the
RAM within your guest machine, but the machine no longer consumes the
RAM of your host machine or CPU cycles while it is suspended.
