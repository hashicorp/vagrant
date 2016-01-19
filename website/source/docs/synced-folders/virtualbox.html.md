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

## Caveats

There is a [VirtualBox bug][sendfile bug] related to `sendfile` which can result
in corrupted or non-updating files. You should deactivate `sendfile` in any
web servers you may be running.

In Nginx:

    sendfile off;

In Apache:

    EnableSendfile Off

[sendfile bug]: https://github.com/mitchellh/vagrant/issues/351#issuecomment-1339640
