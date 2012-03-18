---
layout: documentation
title: Documentation - Vagrantfile - config.vm.network

current: Vagrantfile
---
# config.vm.network

Configuration key: `config.vm.network`

This configuration directive is used to configure networks
available on the virtual machine. Currently, two types of networks
can be used: [host-only](/docs/host_only_networking.html) and
[bridged](/docs/bridged_networking.html). The rest of this documentation
page will assume basic knowledge of these features.

## Host Only Networks

Host only neworks can be defined by providing only a simple IP:

{% highlight ruby %}
Vagrant::Config.run do |config|
  # ...
  config.vm.network :hostonly, "10.11.12.13"
end
{% endhighlight %}

This will configure a host only network on the virtual machine
that is assigned a static IP of "10.11.12.13."

Other options are available for host only networks and may be
passed in as an options hash for the 3rd parameter. The available
options are:

* `:adapter` - The adapter number of the host only network to
  apply the network configuration to.
* `:auto_config` - If `false`, then Vagrant will not attempt to
  automatically configure this network on the guest OS.
* `:mac` - The MAC address to assign to this network adapter.
* `:netmask` - The subnet mask for this network.

## Bridged Networks

Bridged networks can be defined very easily:

{% highlight ruby %}
Vagrant::Config.run do |config|
  # ...
  config.vm.network :bridged
end
{% endhighlight %}

This will enable a bridged network adapter and ask during the configuration
process what network to bridge to.

Other options are available for bridged networking, and may be
passed in as an options hash for the 2nd parameter. The available
options are:

* `:adapter` - The adapter number of the host only network to
  apply the network configuration to.
* `:bridge` - The full name of the network to bridge to. If this is specified,
  then Vagrant will not ask the user.
* `:mac` - The MAC address to assign to this network adapter.
