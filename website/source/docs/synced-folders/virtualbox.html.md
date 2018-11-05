---
layout: "docs"
page_title: "VirtualBox Shared Folders - Synced Folders"
sidebar_current: "syncedfolder-virtualbox"
description: |-
  If you are using the Vagrant VirtualBox provider, then VirtualBox shared
  folders are the default synced folder type. These synced folders use the
  VirtualBox shared folder system to sync file changes from the guest to the
  host and vice versa.
---

# VirtualBox

If you are using the Vagrant VirtualBox [provider](/docs/providers/), then
VirtualBox shared folders are the default synced folder type. These synced
folders use the VirtualBox shared folder system to sync file changes from
the guest to the host and vice versa.

## Options

* `automount` (boolean) - If true, the `--automount` flag will be used when
using the VirtualBox tools to share the folder with the guest vm. Defaults to false
if not present.

* `SharedFoldersEnableSymlinksCreate` (boolean) - If false, will disable the
ability to create symlinks with the given virtualbox shared folder. Defaults to
true if the option is not present.

## Caveats

There is a [VirtualBox bug][sendfile bug] related to `sendfile` which can result
in corrupted or non-updating files. You should deactivate `sendfile` in any
web servers you may be running.

In Nginx:

    sendfile off;

In Apache:

    EnableSendfile Off

[sendfile bug]: https://github.com/hashicorp/vagrant/issues/351#issuecomment-1339640
