---
layout: documentation
title: Documentation - Vagrantfile - config.vm.base_mac

current: Vagrantfile
---
# config.vm.base_mac

Configuration key: `config.vm.base_mac`

Default value: `nil`

This should be set to the MAC address of the NAT interface on the VM at the time
the base image was created. Vagrant currently relies on virtual machines having
a NAT interface that is functional at the time of boot, and Vagrant will set
the MAC address of this interface to this value. The reason this is necessary
is because many operating systems depend on this MAC address for configuration
and changing it may cause the NAT interface to no longer work with the installed
OS.

Typically, this configuration option is set automatically when `vagrant package`
is called, and shouldn't be fiddled with manually.
