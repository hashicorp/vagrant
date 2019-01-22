---
layout: "docs"
page_title: "Networking - VirtualBox Provider"
sidebar_current: "providers-virtualbox-networking"
description: |-
  The Vagrant VirtualBox provider supports using the private network as a
  VirtualBox internal network. By default, private networks are host-only
  networks, because those are the easiest to work with.
---

# Networking

## VirtualBox Internal Network

The Vagrant VirtualBox provider supports using the private network as a
VirtualBox [internal network](https://www.virtualbox.org/manual/ch06.html#network_internal).
By default, private networks are host-only networks, because those are the
easiest to work with. However, internal networks can be enabled as well.

To specify a private network as an internal network for VirtualBox
use the `virtualbox__intnet` option with the network. The `virtualbox__`
(double underscore) prefix tells Vagrant that this option is only for the
VirtualBox provider.

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "private_network", ip: "192.168.50.4",
    virtualbox__intnet: true
end
```

Additionally, if you want to specify that the VirtualBox provider join
a specific internal network, specify the name of the internal network:

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "private_network", ip: "192.168.50.4",
    virtualbox__intnet: "mynetwork"
end
```

## VirtualBox NIC Type

You can specify a specific NIC type for the created network interface
by using the `nic_type` parameter. This is not prefixed by `virtualbox__`
for legacy reasons, but is VirtualBox-specific.

This is an advanced option and should only be used if you know what
you are using, since it can cause the network device to not work at all.

Example:

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "private_network", ip: "192.168.50.4",
    nic_type: "virtio"
end
```
