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

## VirtualBox Host DHCP Server

By default, when specifying a `private_network` with a type of `dhcp` the
Vagrant VirtualBox provider will attempt to find or create an appropriate
host-only network. If the network does not have a DHCP server configured the
provider will attempt to provision one. Sometimes this feature is undesirable.
For example, perhaps resolving dynamic DNS records between guests sharing
a private network is required. The DHCP server built into VirtualBox does
not support dynamic DNS resolution so an alternative is needed.

<div class="alert alert-warning">
  <strong>Advanced topic!</strong> This is a reasonably advanced topic that
  requires configuration outside of Vagrant. The example below requires
  a DHCP server or relay configured outside of VirtualBox responds to
  requests on the designated host-only network.
</div>

To override the default behavior and prevent the Vagrant VirtualBox
provider from creating a DHCP server for the defined host-only network:

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "private_network", type: "dhcp", name: "vboxnet0",
    virtualbox__dhcp_server: false
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
