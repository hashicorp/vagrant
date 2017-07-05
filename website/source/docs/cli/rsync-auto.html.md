---
layout: "docs"
page_title: "vagrant rsync-auto - Command-Line Interface"
sidebar_current: "cli-rsyncauto"
description: |-
  The "vagrant rsync-auto" command watches all local directories of any rsync
  configured synced folders and automatically initiates an rsync transfer when
  changes are detected.
---

# rsync-auto

**Command: `vagrant rsync-auto`**

This command watches all local directories of any
[rsync synced folders](/docs/synced-folders/rsync.html) and automatically
initiates an rsync transfer when changes are detected. This command does
not exit until an interrupt is received.

The change detection is optimized to use platform-specific APIs to listen
for filesystem changes, and does not simply poll the directory.

## Options

* `--[no-]poll` - Force Vagrant to watch for changes using filesystem
    polling instead of filesystem events. This is required for some filesystems
    that do not support events. Warning: enabling this will make `rsync-auto`
    _much_ slower. By default, polling is disabled.

## Machine State Changes

The `rsync-auto` command does not currently handle machine state changes
gracefully. For example, if you start the `rsync-auto` command, then
halt the guest machine, then make changes to some files, then boot it
back up, `rsync-auto` will not attempt to resync.

To ensure that the command works properly, you should start `rsync-auto`
only when the machine is running, and shut it down before any machine
state changes.

You can always force a resync with the [rsync](/docs/cli/rsync.html) command.

## Vagrantfile Changes

If you change or move your Vagrantfile, the `rsync-auto` command will have
to be restarted. For example, if you add synced folders to the Vagrantfile,
or move the directory that contains the Vagrantfile, the `rsync-auto`
command will either not pick up the changes or may begin experiencing
strange behavior.

Before making any such changes, it is recommended that you turn off
`rsync-auto`, then restart it afterwards.
