---
layout: "docs"
page_title: "vagrant global-status - Command-Line Interface"
sidebar_current: "cli-globalstatus"
description: |-
  The "vagrant global-status" command is used to determine the state of all
  active Vagrant environments on the system for the currently logged in user.
---

# Global Status

**Command: `vagrant global-status`**

This command will tell you the state of all active Vagrant environments
on the system for the currently logged in user.

~> **This command does not actively verify the state of machines**,
and is instead based on a cache. Because of this, it is possible to see
stale results (machines say they're running but they're not). For example,
if you restart your computer, Vagrant would not know. To prune the invalid
entries, run global status with the `--prune` flag.

The IDs in the output that look like `a1b2c3` can be used to control
the Vagrant machine from anywhere on the system. Any Vagrant command
that takes a target machine (such as `up`, `halt`, `destroy`) can be
used with this ID to control it. For example: `vagrant destroy a1b2c3`.

## Options

* `--prune` - Prunes invalid entries from the list. This is much more time
  consuming than simply listing the entries.

## Environment Not Showing Up

If your environment is not showing up, you may have to do a `vagrant destroy`
followed by a `vagrant up`.

If you just upgraded from a previous version of Vagrant, existing environments
will not show up in global-status until they are destroyed and recreated.
