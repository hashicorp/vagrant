---
layout: "docs"
page_title: "Limitations - Hyper-V Provider"
sidebar_current: "providers-hyperv-limitations"
description: |-
  The Hyper-V provider works in almost every way like the VirtualBox
  or VMware provider would, but has some limitations that are inherent to
  Hyper-V itself.
---

# Limitations

The Vagrant Hyper-V provider works in almost every way like the VirtualBox
or VMware provider would, but has some limitations that are inherent to
Hyper-V itself.

## Limited Networking

Vagrant does not yet know how to create and configure new networks for
Hyper-V. When launching a machine with Hyper-V, Vagrant will prompt you
asking what virtual switch you want to connect the virtual machine to.

A result of this is that networking configurations in the Vagrantfile
are completely ignored with Hyper-V. Vagrant cannot enforce a static IP
or automatically configure a NAT.

However, the IP address of the machine will be reported as part of
the `vagrant up`, and you can use that IP address as if it were
a host only network.

## Snapshots

Restoring snapshot VMs using `vagrant snapshot pop` or 
`vagrant snapshot restore` will sometimes raise errors when mounting
SMB shared folders, however these mounts will still work inside the guest.


