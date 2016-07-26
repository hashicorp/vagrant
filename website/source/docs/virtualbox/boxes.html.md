---
layout: "docs"
page_title: "Creating a Base Box - VirtualBox Provider"
sidebar_current: "providers-virtualbox-boxes"
description: |-
  As with every Vagrant provider, the Vagrant VirtualBox provider has a custom
  box format that affects how base boxes are made.
---

# Creating a Base Box

As with [every Vagrant provider](/docs/providers/basic_usage.html), the
Vagrant VirtualBox provider has a custom box format that affects how base
boxes are made.

Prior to reading this, you should read the
[general guide to creating base boxes](/docs/boxes/base.html). Actually,
it would probably be most useful to keep this open in a separate tab
as you may be referencing it frequently while creating a base box. That
page contains important information about common software to install
on the box.

Additionally, it is helpful to understand the
[basics of the box file format](/docs/boxes/format.html).

<div class="alert alert-warning">
  <strong>Advanced topic!</strong> This is a reasonably advanced topic that
  a beginning user of Vagrant does not need to understand. If you are
  just getting started with Vagrant, skip this and use an available
  box. If you are an experienced user of Vagrant and want to create
  your own custom boxes, this is for you.
</div>

## Virtual Machine

The virtual machine created in VirtualBox can use any configuration you would
like, but Vagrant has some hard requirements:

  * The first network interface (adapter 1) _must_ be a NAT adapter.
    Vagrant uses this to connect the first time.

  * The MAC address of the first network interface (the NAT adapter)
    should be noted, since you will need to put it in a Vagrantfile
    later as the value for `config.vm.base_mac`. To get this value, use
    the VirtualBox GUI.

Other than the above, you are free to customize the base virtual machine
as you see fit.

## Additional Software

In addition to the software that should be installed based on the
[general guide to creating base boxes](/docs/boxes/base.html),
VirtualBox base boxes require some additional software.

### VirtualBox Guest Additions

[VirtualBox Guest Additions](https://www.virtualbox.org/manual/ch04.html)
must be installed so that things such as shared folders can function.
Installing guest additions also usually improves performance since the guest
OS can make some optimizations by knowing it is running within VirtualBox.

Before installing the guest additions, you will need the linux kernel headers
and the basic developer tools. On Ubuntu, you can easily install these like
so:

```
$ sudo apt-get install linux-headers-$(uname -r) build-essential dkms
```

#### To install via the GUI:

Next, make sure that the guest additions image is available by using the
GUI and clicking on "Devices" followed by "Install Guest Additions".
Then mount the CD-ROM to some location. On Ubuntu, this usually looks like
this:

```
$ sudo mount /dev/cdrom /media/cdrom
```

Finally, run the shell script that matches your system to install the
guest additions. For example, for Linux on x86, it is the following:

```
$ sudo sh /media/cdrom/VBoxLinuxAdditions.run
```

If the command succeeds, then the guest additions are now installed!

#### To install via the command line:

You can find the appropriate guest additions version to match your VirtualBox
version by selecting the appropriate version
[here](http://download.virtualbox.org/virtualbox/). The examples below use
4.3.8, which was the latest VirtualBox version at the time of writing.

```
wget http://download.virtualbox.org/virtualbox/4.3.8/VBoxGuestAdditions_4.3.8.iso
sudo mkdir /media/VBoxGuestAdditions
sudo mount -o loop,ro VBoxGuestAdditions_4.3.8.iso /media/VBoxGuestAdditions
sudo sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run
rm VBoxGuestAdditions_4.3.8.iso
sudo umount /media/VBoxGuestAdditions
sudo rmdir /media/VBoxGuestAdditions
```

If you did not install a Desktop environment when you installed the operating
system, as recommended to reduce size, the install of the VirtualBox additions
should warn you about the lack of OpenGL or Window System Drivers, but you can
safely ignore this.

If the commands succeed, then the guest additions are now installed!

## Packaging the Box

Vagrant includes a simple way to package VirtualBox base boxes. Once you've
installed all the software you want to install, you can run this command:

```
$ vagrant package --base my-virtual-machine
```

Where "my-virtual-machine" is replaced by the name of the virtual machine
in VirtualBox to package as a base box.

It will take a few minutes, but after it is complete, a file "package.box"
should be in your working directory which is the new base box. At this
point, you've successfully created a base box!

## Raw Contents

This section documents the actual raw contents of the box file. This is not
as useful when creating a base box but can be useful in debugging issues
if necessary.

A VirtualBox base box is an archive of the resulting files of
[exporting](https://www.virtualbox.org/manual/ch08.html#vboxmanage-export)
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
the "metadata.json" file used by Vagrant itself.

Also, there is a "Vagrantfile." This contains some configuration to
properly set the MAC address of the NAT network device, since VirtualBox
requires this to be correct in order to function properly. If you are
not using `vagrant package --base` above, you will have to set the
`config.vm.base_mac` setting in this Vagrantfile to the MAC address
of the NAT device without colons.

When bringing up a VirtualBox backed machine, Vagrant
[imports](https://www.virtualbox.org/manual/ch08.html#vboxmanage-import)
the "box.ovf" file found in the box contents.
