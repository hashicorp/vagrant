---
layout: "docs"
page_title: "Private Networks - Networking"
sidebar_current: "networking-private"
description: |-
  Vagrant private networks allow you to access your guest machine by some
  address that is not publicly accessible from the global internet. In general,
  this means your machine gets an address in the private address space.
---

# Private Networks

**Network identifier: `private_network`**

Vagrant private networks allow you to access your guest machine by some address
that is not publicly accessible from the global internet. In general, this
means your machine gets an address in the [private address space](https://en.wikipedia.org/wiki/Private_network#Private_IPv4_address_spaces).

Multiple machines within the same private network (also usually with the
restriction that they're backed by the same [provider](/docs/providers/))
can communicate with each other on private networks.

<div class="alert alert-info">
  <strong>Guest operating system support.</strong> Private networks
  generally require configuring the network adapters on the guest
  machine. This process varies from OS to OS. Vagrant ships with
  knowledge of how to configure networks on a variety of guest
  operating systems, but it is possible if you are using a particularly
  old or new operating system that private networks will not properly
  configure.
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

It is up to the users to make sure that the static IP does not collide
with any other machines on the same network.

While you can choose any IP you would like, you _should_ use an IP from
the [reserved private address space](https://en.wikipedia.org/wiki/Private_network#Private_IPv4_address_spaces). These IPs are guaranteed to never be publicly routable,
and most routers actually block traffic from going to them from the
outside world.

For some operating systems, additional configuration options for the static
IP address are available such as setting the default gateway or MTU.

<div class="alert alert-warning">
  <strong>Warning!</strong> Do not choose an IP that overlaps with any
  other IP space on your system. This can cause the network to not be
  reachable.
</div>

## IPv6

You can specify a static IP via IPv6. DHCP for IPv6 is not supported.
To use IPv6, just specify an IPv6 address as the IP:

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "private_network", ip: "fde4:8dba:82e1::c4"
end
```

This will assign that IP to the machine. The entire `/64` subnet will
be reserved. Please make sure to use the reserved local addresses approved
for IPv6.

You can also modify the prefix length by changing the `netmask` option
(defaults to 64):

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "private_network",
    ip: "fde4:8dba:82e1::c4",
    netmask: "96"
end
```

IPv6 supports for private networks was added in Vagrant 1.7.5 and may
not work with every provider.

## Disable Auto-Configuration

If you want to manually configure the network interface yourself, you
can disable Vagrant's auto-configure feature by specifying `auto_config`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "private_network", ip: "192.168.50.4",
    auto_config: false
end
```

If you already started the Vagrant environment before setting `auto_config`,
the files it initially placed there will stay there. You will have to remove
those files manually or destroy and recreate the machine.

The files created by Vagrant depend on the OS. For example, for many
Linux distros, this is `/etc/network/interfaces`. In general you should
look in the normal location that network interfaces are configured for your
distro.
