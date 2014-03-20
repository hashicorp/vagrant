---
page_title: "Creating a Base Box - VirtualBox Provider"
sidebar_current: "virtualbox-boxes"
---

# Creating a Base Box

As with [every provider](/v2/providers/basic_usage.html), the VirtualBox
provider has a custom box format that affects how base boxes are made.

Prior to reading this, you should read the
[general guide to creating base boxes](/v2/boxes/base.html). Actually,
it would probably be most useful to keep this open in a separate tab
as you may be referencing it frequently while creating a base box. That
page contains important information about common software to install
on the box.

Additionally, it is helpful to understand the
[basics of the box file format](/v2/boxes/format.html).

<div class="alert alert-block alert-warn">
	<p>
		<strong>Advanced topic!</strong> This is a reasonably advanced topic that
		a beginning user of Vagrant doesn't need to understand. If you're
		just getting started with Vagrant, skip this and use an available
		box. If you're an experienced user of Vagrant and want to create
		your own custom boxes, this is for you.
	</p>
</div>

## Additional Software

In addition to the software that should be installed based on the
[general guide to creating base boxes](/v2/boxes/base.html),
VirtualBox base boxes require some additional software.

### VirtualBox Guest Additions

[VirtualBox Guest Additions](http://www.virtualbox.org/manual/ch04.html)
must be installed so that things such as shared folders can function.
Installing guest additions also usually improves performance since the guest
OS can make some optimizations by knowing it is running within VirtualBox.

Before installing the guest additions, you'll need the linux kernel headers
and the basic developer tools. On Ubuntu, you can easily install these like
so:

```
$ sudo apt-get install linux-headers-generic build-essential dkms
```

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

If you didn’t install a Desktop environment when you installed the operating
system, as recommended to reduce size, the install of the VirtualBox additions
should warn you about the lack of OpenGL or Window System Drivers, but you can
safely ignore this.

If the command succeeds, then the guest additions are now installed!

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

This section documents the actual raw contents of the box file. This isn't
as useful when creating a base box but can be useful in debugging issues
if necessary.

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
the "metadata.json" file used by Vagrant itself.

Also, there is a "Vagrantfile." This contains some configuration to
properly set the MAC address of the NAT network device, since VirtualBox
requires this to be correct in order to function properly.

When bringing up a VirtualBox backed machine, Vagrant
[imports](http://www.virtualbox.org/manual/ch08.html#vboxmanage-import)
the first "ovf" file found in the box contents.
