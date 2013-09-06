---
page_title: "vagrant halt - Command-Line Interface"
sidebar_current: "cli-halt"
---

# Halt

**Command: `vagrant halt`**

This command shuts down the running machine Vagrant is managing.

Vagrant will first attempt to gracefully shut down the machine by running
the guest OS shutdown mechanism. If this fails, or if the `--force` flag is
specified, Vagrant will effectively just shut off power to the machine.

## Options

* `-f` or `--force` - Don't attempt to gracefully shut down the machine.
  This effectively pulls the power on the guest machine.
