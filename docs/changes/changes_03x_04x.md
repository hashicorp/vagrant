---
layout: documentation
title: Changes - 0.3.x to 0.4.x
---
# Changes in Vagrant 0.4.x

## VirtualBox 3.2 Support

Vagrant now supports VirtualBox 3.2.0 in addition to the 3.1.x series.
No configuration is necessary; Vagrant will automatically determine which
VirtualBox version is running and use the correct API calls.

## Multi-VM Environments

Vagrant can now automate and manage multiple VMs to represent a single
project. This allows developers to model more complex server setups on
their development machine.

TODO: More explanation + docs.

## Host Only Networking

Prior to 0.4.x, Vagrant could only forward ports via a NAT connection.
Vagrant now allows VMs to specify a static IP for themselves, which
can be accessed on the host machine or any other VMs on the same
host only network. This feature can work hand in hand with the multi-VM
feature announced above to provide efficient internal networking between
VMs.

TODO: Docs

## Automatic Port Collision Fixes

Since version 0.2.0, Vagrant has reported any potential port collisions
for forwarded ports. This was typically a rare occurence which only cropped
up when multiple Vagrant environments were running at the same time. With
the introduction of multi-VM support, port collision is now quite common.
To deal with this, Vagrant can now automatically resolve any port collisions
which are detected.

TODO: Docs

## Minor Changes

### `vagrant provision`

`vagrant provision` can now be called at any time to simply run the provisioning
scripts without having to reload the entire VM environment. There are certain
limitations to this command which are discussed further on the commands
documentation page.

### Many Bug Fixes

As always, a handful of bugs have been fixed since Vagrant 0.3.0.
