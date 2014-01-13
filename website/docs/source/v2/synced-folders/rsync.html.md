---
page_title: "RSync - Synced Folders"
sidebar_current: "syncedfolder-rsync"
---

# RSync

**Synced folder type:** `rsync`

Vagrant can use [rsync](http://en.wikipedia.org/wiki/Rsync) as a mechanism
to sync a folder to the guest machine. This synced folder type is useful
primarily in situations where other synced folder mechanisms are not available,
such as when NFS or VirtualBox shared folders aren't available in the guest
machine.

The rsync synced folder does a one-time one-way sync from the machine running
to the machine being started by Vagrant.

## Prerequisites

To use the rsync synced folder type, the machine running Vagrant must have
`rsync` (or `rsync.exe`) on the path. This executable is expected to behave
like the standard rsync tool.

## Options

The rsync synced folder type accepts the following options:

* `rsync__exclude` (string or array of strings) - A list of files or directories
  to exclude from the sync. The values can be any acceptable rsync exclude
  pattern. By default, the ".vagrant/" directory is excluded. We recommend
  excluding revision control directories such as ".git/" as well.

## Example

The following is an example of using RSync to sync a folder:

<pre class="prettyprint">
Vagrant.configure("2") do |config|
  config.vm.synced_folder ".", "/vagrant", type: "rsync",
    rsync__exclude: ".git/"
end
</pre>

## Re-Syncing

The rsync sync is done only during a `vagrant up` or `vagrant reload`. Vagrant
does not automatically listen for changes on the filesystem and resync them.
Resyncing can be forced with a call to [vagrant rsync](/v2/cli/rsync.html).
