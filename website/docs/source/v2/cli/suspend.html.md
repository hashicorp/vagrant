---
page_title: "vagrant suspend - Command-Line Interface"
sidebar_current: "cli-suspend"
---

# Suspend

**Command: `vagrant suspend`**

This suspends the guest machine Vagrant is managing, rather than fully
[shutting it down](/v2/cli/halt.html) or [destroying it](/v2/cli/destroy.html).

A suspend effectively saves the _exact point-in-time state_ of the machine,
so that when you [resume](/v2/cli/resume.html) it later, it begins running
immediately from that point, rather than doing a full boot.

This generally requires extra disk space to store all the contents of the
RAM within your guest machine, but the machine no longer consumes the
RAM of your host machine or CPU cycles while it is suspended.
