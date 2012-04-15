---
layout: documentation
title: Documentation - Netowrking

current: Networking
---

Vagrant supports 2 kinds of networking

<ul>
	<li><a href="/docs/networking/host_only.html">Host Only</a></li>
	<li><a href="/docs/networking/bridged.html">Bridged</a></li>
</ul>


# Troubleshooting

## Slowness

Networking slowness can be intermittent.
There are some known issues with suspending the host computer causing problems. 
You should be able to fix that by halting the VM and re-starting it.

There are several possible DNS culprits:

### internal resolution

In Ubuntu, for example, there are bugs with mdns.
These can be resolved by disabling it.
The most [nuclear approach](http://www.jedi.be/blog/2011/03/28/using-vagrant-as-a-team/) would be:

    sudo apt-get remove libavahi-common3

### ipv6

You can try disabling ipv6 in your web browser and see if that helps.

### web server resolution 

The ruby web server webrick is the default web server for the development mode of Rails and other web frameworks.
There is a [webrick setting to fix dns lookup](http://nowfromhome.com/virtualbox-slow-network-from-windows-host-to-linux-guest/). Or you can use an alternative web server such as unicorn.
