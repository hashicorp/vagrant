---
layout: "docs"
page_title: "vagrant snapshot - Command-Line Interface"
sidebar_current: "cli-snapshot"
description: |-
  The "vagrant snapshot" command is used to manage snapshots of the guest
  machine.
---

# Snapshot

**Command: `vagrant snapshot`**

This is the command used to manage snapshots with the guest machine.
Snapshots record a point-in-time state of a guest machine. You can then
quickly restore to this environment. This lets you experiment and try things
and quickly restore back to a previous state.

Snapshotting is not supported by every provider. If it is not supported,
Vagrant will give you an error message.

The main functionality of this command is exposed via even more subcommands:

* [`push`](#snapshot-push)
* [`pop`](#snapshot-pop)
* [`save`](#snapshot-save)
* [`restore`](#snapshot-restore)
* [`list`](#snapshot-list)
* [`delete`](#snapshot-delete)

# Snapshot Push

**Command: `vagrant snapshot push`**

This takes a snapshot and pushes it onto the snapshot stack.

This is a shorthand for `vagrant snapshot save` where you do not need
to specify a name. When you call the inverse `vagrant snapshot pop`, it will
restore the pushed state.

~> **Warning:** If you are using `push` and `pop`, avoid using `save`
   and `restore` which are unsafe to mix.

# Snapshot Pop

**Command: `vagrant snapshot pop`**

This command is the inverse of `vagrant snapshot push`: it will restore
the pushed state.

## Options

* `--[no-]provision` - Force the provisioners to run (or prevent them
    from doing so).

* `--no-delete` - Prevents deletion of the snapshot after restoring
    (so that you can restore to the same point again later).

# Snapshot Save

**Command: `vagrant snapshot save [vm-name] NAME`**

This command saves a new named snapshot. If this command is used, the
`push` and `pop` subcommands cannot be safely used.

# Snapshot Restore

**Command: `vagrant snapshot restore [vm-name] NAME`**

This command restores the named snapshot.

* `--[no-]provision` - Force the provisioners to run (or prevent them
    from doing so).

# Snapshot List

**Command: `vagrant snapshot list`**

This command will list all the snapshots taken.

# Snapshot Delete

**Command: `vagrant snapshot delete NAME`**

This command will delete the named snapshot.

Some providers require all "child" snapshots to be deleted first. Vagrant
itself does not track what these children are. If this is the case (such
as with VirtualBox), then you must be sure to delete the snapshots in the
reverse order they were taken.

This command is typically _much faster_ if the machine is halted prior to
snapshotting. If this is not an option, or is not ideal, then the deletion
can also be done online with most providers.
