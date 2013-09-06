---
page_title: "Box Format - VirtualBox Provider"
sidebar_current: "virtualbox-boxes"
---

# Boxes

As with [every provider](/v2/providers/basic_usage.html), the VirtualBox
provider has a custom box format.

This page documents the format so that you can create your own base
boxes. Note that currently you must make these boxes by hand. A future
release of Vagrant will provide additional mechanisms for automatically
creating such images.

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

A VirtualBox base box is an archive of the resulting files of
[exporting](http://www.virtualbox.org/manual/ch08.html#vboxmanage-export)
a VirtualBox virtual machine. Here is an example of what is contained
in such a box:

```
$ tree
.
|-- Vagrantfile
|-- box-disk1.vmdk
|-- box.ovf
|-- metadata.json

0 directories, 4 files
```

In addition to the files from exporting a VirtualBox VM, there is
a "metadata.json" file used by Vagrant itself.

Also, there is a "Vagrantfile." This contains some configuration to
properly set the MAC address of the NAT network device, since VirtualBox
requires this to be correct in order to function properly.

When bringing up a VirtualBox backed machine, Vagrant
[imports](http://www.virtualbox.org/manual/ch08.html#vboxmanage-import)
the first "ovf" file found in the box contents.

## Installed Software

Base boxes for VirtualBox should have the following software installed, as
a bare minimum:

* SSH server with key-based authentication setup. If you want the box to
  work with default Vagrant settings, the SSH user must be set to accept
  the [insecure keypair](https://github.com/mitchellh/vagrant/blob/master/keys/vagrant.pub)
  that ships with Vagrant.

* [VirtualBox Guest Additions](http://www.virtualbox.org/manual/ch04.html) so that things such as shared
  folders can function. There are many other benefits to installing the tools,
  such as improved networking performance.

