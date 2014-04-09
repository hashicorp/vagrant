---
page_title: "Limitations - Hyper-V Provider"
sidebar_current: "hyperv-limitations"
---

# Limitations

The Hyper-V provider works in almost every way like the VirtualBox
or VMware provider would, but has some limitations that are inherent to
Hyper-V itself.

## Limited Networking

Vagrant doesn't yet know how to create and configure new networks for
Hyper-V. When launching a machine with Hyper-V, Vagrant will prompt you
asking what virtual switch you want to connect the virtual machine to.

A result of this is that networking configurations in the Vagrantfile
are completely ignored with Hyper-V. Vagrant can't enforce a static IP
or automatically configure a NAT.

However, the IP address of the machine will be reported as part of
the `vagrant up`, and you can use that IP address as if it were
a host only network.

## Packaging

Vagrant doesn't implement the `vagrant package` command for Hyper-V
yet, though this should be fairly straightforward to add in a Vagrant
release in the near future.
