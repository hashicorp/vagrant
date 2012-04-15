---
layout: documentation
title: Documentation - Host-Only Networking

current: Host-Only Networking
---
# Host-Only Networking

Host-Only networking is a feature of VirtualBox which allows multiple
virtual machines to communicate with each other through a network via
the host machine. The network created by host-only networking is private
to the VMs involved and the host machine. The outside world cannot
join this network.

Vagrant allows users to assign a static IP to a VM, which is then
setup using host-only networking.

<div class="alert alert-block alert-notice">
  <h3>Supported Operating Systems</h3>
  <p>
    Since setting up host-only networking requires configuring the OS to
    use the new interface, this is a system-specific behavior. Try to
    use host only networking with your machine. Vagrant will raise a proper
    error if things don't appear to be working.
  </p>
  <p>
    If you'd like another OS supported, you can add it yourself using a
    <a href="/docs/guests.html">custom guest</a> or you can get in touch
    with a Vagrant developer and assist us in adding it to the core.
  </p>
</div>

## Assigning an IP

Assigning an IP to a virtual machine using Vagrant is simple enough,
using a single configuration directive within the Vagrantfile:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.network :hostonly, "192.168.50.4"
end
{% endhighlight %}

The above will setup the VM with that specific IP. It is up to the user
to make sure that no static IPs will collide with other virtual machines.

<div class="alert alert-block alert-notice">
  <h3>Avoid Using Common Subnets</h3>
  <p>
    The host-only network must not collide with any other active networks.
    If it does, then the routing tables on your computer may not properly
    route the network traffic to the correct subnet. Vagrant will attempt
    to detect when this may happen, but this situation should still be actively
    avoided.
  </p>
</div>

## Multiple Networks

By default, Vagrant uses a netmask of `255.255.255.0`. This means that
as long as the first three parts of the IP are equivalent, VMs will join
the same network. So if two VMs are created with IPs `10.11.12.13` and
`10.11.12.14`, they will be networked together. However, if a VM is
created with an IP of `10.11.20.21`, it will be on a separate network
and will not be able to communicate with the other VMs.

A custom netmask can also be used, although a netmask of `255.255.255.0`
should be sufficient in most cases. An example of using a custom netmask
is shown below:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.network :hostonly, "10.11.12.13", :netmask => "255.255.0.0"
end
{% endhighlight %}

