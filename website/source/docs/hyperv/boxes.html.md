---
layout: "docs"
page_title: "Creating a Base Box - Hyper-V Provider"
sidebar_current: "providers-hyperv-boxes"
description: |-
  As with every Vagrant provider, the Vagrant Hyper-V provider has a custom box
  format that affects how base boxes are made.
---

# Creating a Base Box

As with [every Vagrant provider](/docs/providers/basic_usage.html), the
Vagrant Hyper-V provider has a custom box format that affects how base boxes are made.

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

## Additional Software

In addition to the software that should be installed based on the
[general guide to creating base boxes](/docs/boxes/base.html),
Hyper-V base boxes require some additional software.

### Hyper-V Kernel Modules

You will need to install Hyper-V kernel modules. While this improves performance,
it also enables necessary features such as reporting its IP address so that
Vagrant can access it.

You can verify Hyper-V kernel modules are properly installed by
running `lsmod` on Linux machines and looking for modules prefixed with
`hv_`. Additionally, you will need to verify that the "Network" tab for your
virtual machine in the Hyper-V manager is reporting an IP address. If it
is not reporting an IP address, Vagrant will not be able to access it.

For most newer Linux distributions, the Hyper-V modules will be available
out of the box.

Ubuntu 12.04 requires some special steps to make networking work. These
are reproduced here in case similar steps are needed with other distributions.
Without these commands, Ubuntu 12.04 will not report an IP address to
Hyper-V:

```
$ sudo apt-get install linux-tools-3.11.0-15-generic
$ sudo apt-get install hv-kvp-daemon-init
$ sudo cp /usr/lib/linux-tools/3.11.0-15/hv_* /usr/sbin/
```

## Packaging the Box

To package a Hyper-V box, export the virtual machine from the
Hyper-V Manager using the "Export" feature. This will create a directory
with a structure similar to the following:

```
.
|-- Snapshots
|-- Virtual Hard drives
|-- Virtual Machines
```

Delete the "Snapshots" folder. It is of no use to the Vagrant Hyper-V
provider and can only add to the size of the box if there are snapshots
in that folder.

Then, create the "metadata.json" file necessary for the box, as documented
in [basics of the box file format](/docs/boxes/format.html). The proper
provider value to use for the metadata is "hyperv".

Finally, create an archive of those contents (but _not_ the parent folder)
using a tool such as `tar`:

```
$ tar cvzf ~/custom.box ./*
```

A common mistake is to also package the parent folder by accident. Vagrant
will not work in this case. To verify you've packaged it properly, add the
box to Vagrant and try to bring up the machine.

## Additional Help

There is also some less structured help available from the experience of
other users. These are not official documentation but if you are running
into trouble they may help you:

  * [Ubuntu 14.04.2 without secure boot](https://github.com/mitchellh/vagrant/issues/5419#issuecomment-86235427)
