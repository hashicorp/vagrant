---
layout: "docs"
page_title: "vagrant status - Command-Line Interface"
sidebar_current: "cli-status"
description: |-
  The "vagrant status" command is used to tell you the status of the virtual
  machines in the current Vagrant environment.
---

# Status

**Command: `vagrant status [name|id]`**

This will tell you the state of the machines Vagrant is managing.

It is quite easy, especially once you get comfortable with Vagrant, to
forget whether your Vagrant machine is running, suspended, not created, etc.
This command tells you the state of the underlying guest machine.
