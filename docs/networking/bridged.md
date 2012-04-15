---
layout: documentation
title: Documentation - Bridged Networking

current: Bridged Networking
---
# Bridged Networking

Bridged networking is another type of networking that VirtualBox
provides which causes the virtual machine to appear as another
physical device on your network. Your virtual machine will ask for
an IP from the network via DHCP and will be visible just like any
other machine.

Vagrant exposes this feature in a straightforward and easy to use
way.

<div class="alert alert-block alert-notice">
  <h3>Supported Operating Systems</h3>
  <p>
    Since setting up bridged networking requires configuring the OS to
    use the new interface, this is a guest-specific behavior. Currently,
    Vagrant supports a small set of operation systems.
  </p>
  <p>
    If you'd like another OS supported, you can add it yourself using a
    <a href="/docs/guests.html">custom guest</a> or you can get in touch
    with a Vagrant developer and assist us in adding it to the core.
  </p>
</div>

## Enabling a Bridged Network

Enabling a bridged network on a virtual machine managed by Vagrant
is simple enough, using a single configuration directive in the
Vagrantfile:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.network :bridged
end
{% endhighlight %}

The above will tell Vagrant to setup a bridged network interface.
Vagrant will always setup this bridged interface as adapter #3 on
the virtual machine. This can be overridden as well, see below for more
information.

<div class="alert alert-block alert-notice">
  <h3>Not All Networks Work!</h3>
  <p>
    Some networks will not work properly with bridged networking. Specifically,
    I've found that hotel networks, airport networks, and generally public-shared
    networks have configurations in place such that bridging does not work.
  </p>
  <p>
    You can tell if the bridged networking worked successfully by seeing if the
    virtual machine was able to get an IP address on the bridged adapter.
  </p>
</div>

## Determining the IP of the Virtual Machine

Unlike [host-only networks](/docs/host_only_networking.html), Vagrant does
not know the IP that the bridged network will receive a priori. Instead,
it is up to your network to lease your virtual machine an IP via DHCP.
Because of this, the IP address can only be determined by SSHing into
the virtual machine and inspecting the adapters yourself.

For example, on an Ubuntu-powered virtual machine, by running `ifconfig`
it is easy to see what the IP address of the bridged adapter is:

{% highlight bash %}
$ ifconfig
...

eth2      Link encap:Ethernet  HWaddr 08:00:27:df:63:62
          inet addr:192.168.1.3  Bcast:192.168.1.255  Mask:255.255.255.0
          inet6 addr: fe80::a00:27ff:fedf:6362/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:24 errors:0 dropped:0 overruns:0 frame:0
          TX packets:20 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:4380 (4.3 KB)  TX bytes:2088 (2.0 KB)
{% endhighlight %}

In the above output, we can see that `eth2` has an IP address of
`192.168.1.3`. This is the IP address of the bridged adapter.
