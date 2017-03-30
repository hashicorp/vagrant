---
layout: "docs"
page_title: "Box Format - VMware Provider"
sidebar_current: "providers-vmware-boxes"
description: |-
  As with every Vagrant provider, the Vagrant VMware providers have a custom box
  format.
---

# Boxes

As with [every Vagrant provider](/docs/providers/basic_usage.html), the
Vagrant VMware providers have a custom box format.

This page documents the format so that you can create your own base boxes.
Note that currently you must make these base boxes by hand. A future release
of Vagrant will provide additional mechanisms for automatically creating such
images.

<div class="alert alert-info">
  <strong>Note:</strong> This is a reasonably advanced topic that
  a beginning user of Vagrant does not need to understand. If you are
  just getting started with Vagrant, skip this and use an available
  box. If you are an experienced user of Vagrant and want to create
  your own custom boxes, this is for you.
</div>

Prior to reading this page, please understand the
[basics of the box file format](/docs/boxes/format.html).

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
[box format](/docs/boxes/format.html) page.

When bringing up a VMware backed machine, Vagrant copies all of the contents
in the box into a privately managed "vmwarevm" folder, and uses the first
"vmx" file found to control the machine.

<div class="alert alert-info">
  <strong>Vagrant 1.8 and higher support linked clones</strong>. Prior versions
  of Vagrant do not support linked clones. For more information on
  linked clones, please see the documentation.
</div>

## VMX Whitelisting

Settings in the VMX file control the behavior of the VMware virtual machine
when it is booted. In the past Vagrant has removed the configured network
device when creating a new instance and inserted a new configuration. With
the introduction of ["predictable network interface names"][iface-names] this
approach can cause unexpected behaviors or errors with VMware Vagrant boxes.
While some boxes that use the predictable network interface names are configured
to handle the VMX modifications Vagrant makes, it is better if Vagrant does
not make the modification at all.

Vagrant will now warn if a whitelisted setting is detected within a Vagrant
box VMX file. If it is detected, a warning will be shown alerting the user
and providing a configuration snippet. The configuration snippet can be
used in the Vagrantfile if Vagrant fails to start the virtual machine.

### Making compatible boxes

These are the VMX settings the whitelisting applies to:

* `ethernet*.pcislotnumber`

If the newly created box does not depend on Vagrant's existing behavior of
modifying this setting, it can disable Vagrant from applying the modification
by adding a Vagrantfile to the box with the following content:

```ruby
Vagrant.configure("2") do |config|
  ["vmware_workstation", "vmware_fusion"].each do |vmware_provider|
    config.vm.provider(vmware_provider) do |vmware|
      vmware.whitelist_verified = true
    end
  end
end
```

This will prevent Vagrant from displaying a warning to the user as well as
disable the VMX settings modifications.

## Installed Software

Base boxes for VMware should have the following software installed, as
a bare minimum:

* SSH server with key-based authentication setup. If you want the box to
  work with default Vagrant settings, the SSH user must be set to accept
  the [insecure keypair](https://github.com/mitchellh/vagrant/blob/master/keys/vagrant.pub)
  that ships with Vagrant.

* [VMware Tools](https://kb.vmware.com/kb/340) so that things such as shared
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

[iface-names]: https://www.freedesktop.org/wiki/Software/systemd/PredictableNetworkInterfaceNames/
