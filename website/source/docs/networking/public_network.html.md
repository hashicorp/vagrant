---
layout: "docs"
page_title: "Public Networks - Networking"
sidebar_current: "networking-public"
description: |-
  Vagrant public networks are less private than private networks, and the exact
  meaning actually varies from provider to provider, hence the ambiguous
  definition. The idea is that while private networks should never allow the
  general public access to your machine, public networks can.
---

# Public Networks

**Network identifier: `public_network`**

Vagrant public networks are less private than private networks, and the exact
meaning actually varies from [provider to provider](/docs/providers/),
hence the ambiguous definition. The idea is that while
[private networks](/docs/networking/private_network.html) should never allow the
general public access to your machine, public networks can.

<div class="alert alert-info">
  <strong>Confused?</strong> We kind of are, too. It is likely that
  public networks will be replaced by <code>:bridged</code> in a
  future release, since that is in general what should be done with
  public networks, and providers that do not support bridging generally
  do not have any other features that map to public networks either.
</div>

<div class="alert alert-warning">
  <strong>Warning!</strong> Vagrant boxes are insecure by default
  and by design, featuring public passwords, insecure keypairs
  for SSH access, and potentially allow root access over SSH.  With
  these known credentials, your box is easily accessible by anyone on
  your network.  Before configuring Vagrant to use a public network,
  consider <em>all</em> potential security implications
  and review the <a href="/docs/boxes/base.html">default box
  configuration</a> to identify potential security risks.
</div>

## DHCP

The easiest way to use a public network is to allow the IP to be assigned
via DHCP. In this case, defining a public network is trivially easy:

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "public_network"
end
```

When DHCP is used, the IP can be determined by using `vagrant ssh` to
SSH into the machine and using the appropriate command line tool to find
the IP, such as `ifconfig`.

### Using the DHCP Assigned Default Route

Some cases require the DHCP assigned default route to be untouched. In these cases one
may specify the `use_dhcp_assigned_default_route` option. As an example:

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "public_network",
    use_dhcp_assigned_default_route: true
end
```

## Static IP

Depending on your setup, you may wish to manually set the IP of your
bridged interface. To do so, add a `:ip` clause to the network definition.

```ruby
config.vm.network "public_network", ip: "192.168.0.17"
```

## Default Network Interface

If more than one network interface is available on the host machine, Vagrant will
ask you to choose which interface the virtual machine should bridge to. A default
interface can be specified by adding a `:bridge` clause to the network definition.

```ruby
config.vm.network "public_network", bridge: "en1: Wi-Fi (AirPort)"
```

The string identifying the desired interface must exactly match the name of an
available interface. If it cannot be found, Vagrant will ask you to pick
from a list of available network interfaces.

With some providers, it is possible to specify a list of adapters to bridge
against:

```ruby
config.vm.network "public_network", bridge: [
  "en1: Wi-Fi (AirPort)",
  "en6: Broadcom NetXtreme Gigabit Ethernet Controller",
]
```

In this example, the first network adapter that exists and can successfully be
bridge will be used.

## Disable Auto-Configuration

If you want to manually configure the network interface yourself, you
can disable auto-configuration by specifying `auto_config`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "public_network", auto_config: false
end
```

Then the shell provisioner can be used to configure the ip of the interface:

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "public_network", auto_config: false

  # manual ip
  config.vm.provision "shell",
    run: "always",
    inline: "ifconfig eth1 192.168.0.17 netmask 255.255.255.0 up"

  # manual ipv6
  config.vm.provision "shell",
    run: "always",
    inline: "ifconfig eth1 inet6 add fc00::17/7"
end
```

## Default Router

Depending on your setup, you may wish to manually override the default
router configuration. This is required if you need access the Vagrant box from
other networks over the public network. To do so, you can use a shell
provisioner script:

```ruby
Vagrant.configure("2") do |config|
  config.vm.network "public_network", ip: "192.168.0.17"

  # default router
  config.vm.provision "shell",
    run: "always",
    inline: "route add default gw 192.168.0.1"

  # default router ipv6
  config.vm.provision "shell",
    run: "always",
    inline: "route -A inet6 add default gw fc00::1 eth1"

  # delete default gw on eth0
  config.vm.provision "shell",
    run: "always",
    inline: "eval `route -n | awk '{ if ($8 ==\"eth0\" && $2 != \"0.0.0.0\") print \"route del default gw \" $2; }'`"
end
```

Note the above is fairly complex and may be guest OS specific, but we
document the rough idea of how to do it because it is a common question.
