---
layout: "docs"
page_title: "vagrant halt - Command-Line Interface"
sidebar_current: "cli-halt"
description: |-
  The "vagrant halt" command is used to shut down the virtual machine that
  Vagrant is currently managing.
---

# Halt

**Command: `vagrant halt [name|id]`**

This command shuts down the running machine Vagrant is managing.

Vagrant will first attempt to gracefully shut down the machine by running
the guest OS shutdown mechanism. If this fails, or if the `--force` flag is
specified, Vagrant will effectively just shut off power to the machine.

For linux-based guests, Vagrant uses the `shutdown` command to gracefully
terminate the machine. Due to the varying nature of operating systems, the
`shutdown` command may exist at many different locations in the guest's `$PATH`.
It is the guest machine's responsibility to properly populate the `$PATH` with
directory containing the `shutdown` command.

## Options

* `-f` or `--force` - Do not attempt to gracefully shut down the machine.
  This effectively pulls the power on the guest machine.
