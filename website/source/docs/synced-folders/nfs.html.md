---
layout: "docs"
page_title: "NFS - Synced Folders"
sidebar_current: "syncedfolder-nfs"
description: |-
  In some cases the default shared folder implementations such as VirtualBox
  shared folders have high performance penalties. If you are seeing less than
  ideal performance with synced folders, NFS can offer a solution. Vagrant has
  built-in support to orchestrate the configuration of the NFS server on the host
  and guest for you.
---

# NFS

In some cases the default shared folder implementations (such as VirtualBox
shared folders) have high performance penalties. If you are seeing less
than ideal performance with synced folders, [NFS](https://en.wikipedia.org/wiki/Network_File_System_%28protocol%29)
can offer a solution. Vagrant has built-in support to orchestrate the
configuration of the NFS server on the host and guest for you.

~> **Windows users:** NFS folders do not work on Windows hosts. Vagrant will
ignore your request for NFS synced folders on Windows.

## Prerequisites

Before using synced folders backed by NFS, the host machine must have
`nfsd` installed, the NFS server daemon. This comes pre-installed on Mac
OS X, and is typically a simple package install on Linux.

Additionally, the guest machine must have NFS support installed. This is
also usually a simple package installation away.

If you are using the VirtualBox provider, you will also need to make sure you
have a
[private network set up](/docs/networking/private_network.html). This is due to a limitation of VirtualBox's built-in networking. With
VMware, you do not need this.

## Enabling NFS Synced Folders

To enable NFS, just add the `type: "nfs"` flag onto your synced folder:

```ruby
Vagrant.configure("2") do |config|
  config.vm.synced_folder ".", "/vagrant", type: "nfs"
end
```

If you add this to an existing Vagrantfile that has a running guest machine,
be sure to `vagrant reload` to see your changes.

## NFS Synced Folder Options

NFS synced folders have a set of options that can be specified that are
unique to NFS. These are listed below. These options can be specified in
the final part of the `config.vm.synced_folder` definition, along with the
`type` option.

* `nfs_export` (boolean) - If this is false, then Vagrant will not modify
  your `/etc/exports` automatically and assumes you've done so already.

* `nfs_udp` (boolean) - Whether or not to use UDP as the transport. UDP
  is faster but has some limitations (see the NFS documentation for more
  details). This defaults to true.

* `nfs_version` (string | integer) - The NFS protocol version to use when
  mounting the folder on the guest. This defaults to 3.

## NFS Global Options

There are also more global NFS options you can set with `config.nfs` in
the Vagrantfile. These are documented below:

* `functional` (bool) - Defaults to true. If false, then NFS will not be used
  as a synced folder type. If a synced folder specifically requests NFS,
  it will error.

* `map_uid` and `map_gid` (int) - The UID/GID, respectively, to map all
  read/write requests too. This will not affect the owner/group within the
  guest machine itself, but any writes will behave as if they were written
  as this UID/GID on the host. This defaults to the current user running
  Vagrant.

* `verify_installed` (bool) - Defaults to true. If this is false, then
  Vagrant will skip checking if NFS is installed.

## Specifying NFS Arguments

In addition to the options specified above, it is possible for Vagrant to
specify alternate NFS arguments when mounting the NFS share by using the
`mount_options` key. For example, to use the `actimeo=2` client mount option:

```ruby
config.vm.synced_folder ".", "/vagrant",
  nfs: true,
  mount_options: ['actimeo=2']
```

This would result in the following `mount` command being executed on the guest:

```
mount -o 'actimeo=2' 172.28.128.1:'/path/to/vagrantfile' /vagrant
```

You can also tweak the arguments specified in the `/etc/exports` template
when the mount is added, by using the OS-specific `linux__nfs_options` or
`bsd__nfs_options` keys. Note that these options completely override the default
arguments that are added by Vagrant automatically. For example, to make the
NFS share asynchronous:

```ruby
config.vm.synced_folder ".", "/vagrant",
  nfs: true,
  linux__nfs_options: ['rw','no_subtree_check','all_squash','async']
```

This would result in the following content in `/etc/exports` on the host (note
the added `async` flag):

```
# VAGRANT-BEGIN: 21171 5b8f0135-9e73-4166-9bfd-ac43d5f14261
"/path/to/vagrantfile" 172.28.128.5(rw,no_subtree_check,all_squash,async,anonuid=21171,anongid=660,fsid=3382034405)
# VAGRANT-END: 21171 5b8f0135-9e73-4166-9bfd-ac43d5f14261
```

## Root Privilege Requirement

To configure NFS, Vagrant must modify system files on the host. Therefore,
at some point during the `vagrant up` sequence, you may be prompted for
administrative privileges (via the typical `sudo` program). These
privileges are used to modify `/etc/exports` as well as to start and
stop the NFS server daemon.

If you do not want to type your password on every `vagrant up`, Vagrant
uses thoughtfully crafted commands to make fine-grained sudoers modifications
possible to avoid entering your password.

Below, we have a couple example sudoers entries. Note that you may
have to modify them _slightly_ on certain hosts because the way Vagrant
modifies `/etc/exports` changes a bit from OS to OS. If the commands below
are located in non-standard paths, modify them as appropriate.

For \*nix users, make sure to edit your `/etc/sudoers` file with `visudo`. It protects you against syntax errors which could leave you without the ability to gain elevated privileges.

All of the snippets below require Vagrant version 1.7.3 or higher.

<div class="alert alert-warning" role="alert">
  <strong>Use the appropiate group for your user</strong> Depending on how your machine is
   configured, you might need to use a different group than the ones listed in the examples below.
</div>

For OS X, sudoers should have this entry:

```
Cmnd_Alias VAGRANT_EXPORTS_ADD = /usr/bin/tee -a /etc/exports
Cmnd_Alias VAGRANT_NFSD = /sbin/nfsd restart
Cmnd_Alias VAGRANT_EXPORTS_REMOVE = /usr/bin/sed -E -e /*/ d -ibak /etc/exports
%admin ALL=(root) NOPASSWD: VAGRANT_EXPORTS_ADD, VAGRANT_NFSD, VAGRANT_EXPORTS_REMOVE
```

For Ubuntu Linux , sudoers should look like this:

```
Cmnd_Alias VAGRANT_EXPORTS_CHOWN = /bin/chown 0\:0 /tmp/*
Cmnd_Alias VAGRANT_EXPORTS_MV = /bin/mv -f /tmp/* /etc/exports
Cmnd_Alias VAGRANT_NFSD_CHECK = /etc/init.d/nfs-kernel-server status
Cmnd_Alias VAGRANT_NFSD_START = /etc/init.d/nfs-kernel-server start
Cmnd_Alias VAGRANT_NFSD_APPLY = /usr/sbin/exportfs -ar
%sudo ALL=(root) NOPASSWD: VAGRANT_EXPORTS_CHOWN, VAGRANT_EXPORTS_MV, VAGRANT_NFSD_CHECK, VAGRANT_NFSD_START, VAGRANT_NFSD_APPLY
```

For Fedora Linux, sudoers might look like this (given your user
belongs to the vagrant group):

```
Cmnd_Alias VAGRANT_EXPORTS_CHOWN = /bin/chown 0\:0 /tmp/*
Cmnd_Alias VAGRANT_EXPORTS_MV = /bin/mv -f /tmp/* /etc/exports
Cmnd_Alias VAGRANT_NFSD_CHECK = /usr/bin/systemctl status --no-pager nfs-server.service
Cmnd_Alias VAGRANT_NFSD_START = /usr/bin/systemctl start nfs-server.service
Cmnd_Alias VAGRANT_NFSD_APPLY = /usr/sbin/exportfs -ar
%vagrant ALL=(root) NOPASSWD: VAGRANT_EXPORTS_CHOWN, VAGRANT_EXPORTS_MV, VAGRANT_NFSD_CHECK, VAGRANT_NFSD_START, VAGRANT_NFSD_APPLY
```

If you don't want to edit `/etc/sudoers` directly, you can create
`/etc/sudoers.d/vagrant-syncedfolders` with the appropriate entries,
assuming `/etc/sudoers.d` has been enabled.

## Other Notes

**Encrypted folders:** If you have an encrypted disk, then NFS very often
will refuse to export the filesystem. The error message given by NFS is
often not clear. One error message seen is `<path> does not support NFS`.
There is no workaround for this other than sharing a directory which is not
encrypted.

**Version 4:** UDP is generally not a valid transport protocol for NFSv4.
Early implementations of NFS 4.0 still allowed UDP which allows the UDP
transport protocol to be used in rare cases. RFC5661 explicitly states
UDP alone should not be used for the transport protocol in NFS 4.1. Errors
due to unsupported transport protocols for specific versions of NFS are
not always clear. A common error message when attempting to use UDP with
NFSv4:

```
mount.nfs: an incorrect mount option was specified
```

When using NFSv4, ensure the `nfs_udp` option is set to false. For example:

```ruby
config.vm.synced_folder ".", "/vagrant",
  nfs: true,
  nfs_version: 4,
  nfs_udp: false
```

For more information about transport protocols and NFS version 4 see:

* NFSv4.0 - [RFC7530](https://tools.ietf.org/html/rfc7530#section-3.1)
* NFSv4.1 - [RFC5661](https://tools.ietf.org/html/rfc5661#section-2.9.1)
