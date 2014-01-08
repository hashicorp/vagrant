---
page_title: "Private Networks - Networking"
sidebar_current: "networking-private"
---

# Private Networks

**Network identifier: `private_network`**

Private networks allow you to access your guest machine by some address
that is not publicly accessible from the global internet. In general, this
means your machine gets an address in the [private address space](http://en.wikipedia.org/wiki/Private_network#Private_IPv4_address_spaces).

Multiple machines within the same private network (also usually with the
restriction that they're backed by the same [provider](/v2/providers/index.html))
can communicate with each other on private networks.

<div class="alert alert-info">
	<p>
		<strong>Guest operating system support.</strong> Private networks
		generally require configuring the network adapters on the guest
		machine. This process varies from OS to OS. Vagrant ships with
		knowledge of how to configure networks on a variety of guest
		operating systems, but it is possible if you're using a particularly
		old or new operating system that private networks won't properly
		configure.
	</p>
</div>

## Static IP

The easiest way to use a private network is to assign a static IP to it.
This let's you access the Vagrant managed machine using a static, known
IP. The Vagrantfile for a static IP looks like this:

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "private_network", ip: "192.168.50.4"
end
```

It is up to the users to make sure that the static IP doesn't collide
with any other machines on the same network.

While you can choose any IP you'd like, you _should_ use an IP from
the [reserved private address space](http://en.wikipedia.org/wiki/Private_network#Private_IPv4_address_spaces). These IPs are guaranteed to never be publicly routable,
and most routers actually block traffic from going to them from the
outside world.

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
    virtualbox__intnet: "true"
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
