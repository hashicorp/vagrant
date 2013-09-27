---
page_title: "Box Format - VMware Provider"
sidebar_current: "vmware-boxes"
---

# Boxes

As with [every provider](/v2/providers/basic_usage.html), the VMware
providers have a custom box format.

This page documents the format so that you can create your own base boxes.
Note that currently you must make these base boxes by hand. A future release
of Vagrant will provide additional mechanisms for automatically creating such
images.

<div class="alert alert-info">
	<p>
		<strong>Note:</strong> This is a reasonably advanced topic that
		a beginning user of Vagrant doesn't need to understand. If you're
		just getting started with Vagrant, skip this and use an available
		box. If you're an experienced user of Vagrant and want to create
		your own custom boxes, this is for you.
	</p>
</div>

Prior to reading this page, please understand the
[basics of the box file format](/v2/boxes/format.html).

## Contents

A VMware base box is a compressed archive of the necessary contents
of a VMware "vmwarevm" file. Here is an example of what is contained
in such a box:

```
$ tree
.
|-- disk-s001.vmdk
|-- disk-s002.vmdk
|-- ...
|-- disk.vmdk
|-- metadata.json
|-- precise64.nvram
|-- precise64.vmsd
|-- precise64.vmx
|-- precise64.vmxf

0 directories, 17 files
```

The files that are strictly required for a VMware machine to function are:
nvram, vmsd, vmx, vmxf, and vmdk files.

There is also the "metadata.json" file used by Vagrant itself. This file
contains nothing but the defaults which are documented on the
[box format](/v2/boxes/format.html) page.

When bringing up a VMware backed machine, Vagrant copies all of the contents
in the box into a privately managed "vmwarevm" folder, and uses the first
"vmx" file found to control the machine.

<div class="alert alert-info">
	<h3>Linked Clones</h3>
	<p>
		A future version of the VMware provider will implement
		linked cloning.
	</p>
</div>

## Installed Software

Base boxes for VMware should have the following software installed, as
a bare minimum:

* SSH server with key-based authentication setup. If you want the box to
  work with default Vagrant settings, the SSH user must be set to accept
  the [insecure keypair](https://github.com/mitchellh/vagrant/blob/master/keys/vagrant.pub)
  that ships with Vagrant.

* [VMware Tools](http://kb.vmware.com/kb/340) so that things such as shared
  folders can function. There are many other benefits to installing the tools,
  such as improved networking performance.

## Optimizing Box Size

Prior to packaging up a box, you should shrink the hard drives as much as
possible. This can be done with `vmware-vdiskmanager` which is usually
found in `/Applications/VMware Fusion.app/Contents/Library` for VMware Fusion. You first
want to defragment then shrink the drive. Usage shown below:

```
$ vmware-vdiskmanager -d /path/to/main.vmdk
...
$ vmware-vdiskmanager -k /path/to/main.vmdk
...
```

## Packaging

Remove any extraneous files from the "vmwarevm" folder
and package it. Be sure to compress the tar with gzip (done below in a
single command) since VMware hard disks are not compressed by default.

```
$ cd /path/to/my/vm.vmwarevm
$ tar cvzf custom.box ./*
```
