---
page_title: "Networking - VirtualBox Provider"
sidebar_current: "virtualbox-networking"
---

# Networking

## VirtualBox Internal Network

The VirtualBox provider supports using the private network as a
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
