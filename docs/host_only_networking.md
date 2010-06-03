---
layout: documentation
title: Documentation - Host-Only Networking
---
# Host-Only Networking

Host-Only networking is a feature of VirtualBox which allows multiple
virtual machines to communicate with each other through a network via
the host machine. The network created by host-only networking is private
to the VMs involved and the host machine. The outside world cannot
join this network.

Vagrant allows users to assign a static IP to a VM, which is then
setup using host-only networking.

<div class="info">
  <h3>Debian/Ubuntu Only!</h3>
  <p>
    Since setting up host-only networking requires configuring the OS to
    use the new interface, this is a system behavior. Currently, Vagrant
    only supports Ubuntu/Debian out of the box.
  </p>
  <p>
    If you'd like another OS supported, you can add it yourself using a
    <a href="/docs/systems.html">custom system</a> or you can get in touch
    with a Vagrant developer and assist us in adding it to the core.
  </p>
</div>

## Assigning an IP

Assigning an IP to a virtual machine using Vagrant is simple enough,
using a single function within the Vagrantfile:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.network("192.168.10.10")
end
{% endhighlight %}

The above will setup the VM with that specific IP. It is up to the user
to make sure that no static IPs will collide with other virtual machines.

## Multiple Networks

By default, Vagrant uses a netmask of `255.255.255.0`. This means that
as long as the first three parts of the IP are equivalent, VMs will join
the same network. So if two VMs are created with IPs `192.168.10.10` and
`192.168.10.11`, they will be networked together. However, if a VM is
created with an IP of `192.168.11.10`, it will be on a separate network
and will not be able to communicate with the other VMs.

A custom netmask can also be used, although a netmask of `255.255.255.0`
should be sufficient in most cases. An example of using a custom netmask
is shown below:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.network("192.168.11.10", :netmask => "255.255.0.0")
end
{% endhighlight %}

