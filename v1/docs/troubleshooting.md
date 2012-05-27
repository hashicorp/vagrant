---
layout: documentation
title: Documentation - Troubleshooting Common Problems

current: Troubleshooting
---
# Troubleshooting

Fixes for some common problems are denoted on this page. If the suggestions on
this page don't work, try [using Vagrant's debug log](/docs/debugging.html) or
[asking for support](/support.html).

## Mount error on v-root: /vagrant

When you start up your guest, you may get the following message unexpectedly:

{% highlight text %}
[default] -- v-root: /vagrant
The following SSH command responded with a non-zero exit status.
Vagrant assumes that this means the command failed!

mount -t vboxsf -o uid=`id -u vagrant`,gid=`id -g vagrant` v-root /vagrant
{% endhighlight %}

This is usually a result of the guest's package manager upgrading the kernel
without rebuilding the VirtualBox Guest Additions. To double-check that this
is the issue, connect to the guest and issue the following command:

    lsmod | grep vboxsf

If that command does not return any output, it means that the VirtualBox Guest
Additions are not loaded. If the VirtualBox Guest Additions were previously
installed on the machine, you will more than likely be able to rebuild them
for the new kernel through the `vboxadd` initscript, like so:

    sudo /etc/init.d/vboxadd setup


## Networking Slowness

Networking slowness can be intermittent.
There are some known issues with suspending the host computer causing problems. 
You should be able to fix that by halting the VM and re-starting it.

There are also several possible DNS culprits that you can fix:


### internal resolution

In Ubuntu, for example, there are bugs with mdns.
These can be resolved by disabling it.
The most [nuclear approach](http://www.jedi.be/blog/2011/03/28/using-vagrant-as-a-team/) would be:

    sudo apt-get remove libavahi-common3

### ipv6

You can try disabling ipv6 in your web browser and see if that helps.

### web server resolution 

The ruby web server webrick is the web server used by default for the development mode of Rails and also used by some other ruby projects.
There is a [webrick setting to fix dns lookup](http://nowfromhome.com/virtualbox-slow-network-from-windows-host-to-linux-guest/). Or you can use an alternative web server such as unicorn.
