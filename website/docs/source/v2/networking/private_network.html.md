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

## DHCP

The easiest way to use a private network is to allow the IP to be assigned
via DHCP.

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "private_network", type: "dhcp"
end
```

This will automatically assign an IP address from the reserved address space.
The IP address can be determined by using `vagrant ssh` to SSH into the
machine and using the appropriate command line tool to find the IP,
such as `ifconfig`.

## Static IP

You can also specify a static IP address for the machine. This lets you
access the Vagrant managed machine using a static, known IP. The
Vagrantfile for a static IP looks like this:

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

## Disable Auto-Configuration

If you want to manually configure the network interface yourself, you
can disable Vagrant's auto-configure feature by specifying `auto_config`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "private_network", ip: "192.168.50.4",
    auto_config: false
end
```
