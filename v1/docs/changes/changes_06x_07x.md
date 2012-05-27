---
layout: documentation
title: Changes - 0.6.x to 0.7.x
---
# Changes from Vagrant 0.6.x to 0.7.x

Vagrant 0.7.0 is another major release for Vagrant, with over 200 commits
touching around 150 files. The goal of Vagrant 0.7 was to support VirtualBox 4
while also bringing support for more guest operating systems and provisioners.
This has been achieved and more! Read on for more information.

**Backwards incompatible changes!** There are backwards incompatible changes,
specifically with the provisioner syntax in Vagrantfiles. Read the "New Vagrantfile
Provisioner Syntax" section below for more information. This is _very important_.

## VirtualBox 4 Support, VirtualBox 3.x Dropped

This is a **backwards incompatible** change.

Perhaps most importantly, Vagrant 0.7.0 is fully compatible with VirtualBox 4,
Oracles recent major release of VirtualBox released on December 21, 2010. The
API changes were so great, however, that supporting both VirtualBox 4 and
VirtualBox 3.x was out of the question. Because of this, if you or your company
is stuck with VirtualBox 3.x, please stick with the 0.6.x line of Vagrant
until you can upgrade VirtualBox.

With VirtualBox 4, VM import and export is noticably faster. Everything should
behave normally.

The `lucid32` and `lucid64` base boxes have been updated to have the
VirtualBox 4 guest additions, as well.

## New Vagrantfile Provisioner Syntax

This is a **backwards incompatible** change.

The syntax for enabling and configuring provisioners in Vagrantfiles has been
completely redone, most importantly to make enabling provisioners more consistent
with the rest of the syntax, but also to enable multiple provisioners to be
run. Below is an example of the new syntax, and all the relevant documentation
on the website has been updated to reflect the change:

{% highlight ruby %}
Vagrant::Config.run do |config|
  # Using a hash to set the options
  config.vm.provision :chef_solo, :cookbooks_path => "my_cookbooks"

  # Or perhaps using a block...
  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = "my_cookbooks"
    chef.add_recipe "apache"
  end

  # The above two methods of configuring the provisioner can be used
  # in conjunction as well.
{% endhighlight %}

For those Vagrantfiles which still use the old `config.vm.provisioner =`
syntax, you should see a large, friendly error message describing this
new change. This error message will be removed with Vagrant 0.8.0.

## Puppet Support

Thanks to [James Turnbull](http://www.james-turnbull.net/), Vagrant now has
built-in provisioners for both standalone [Puppet](http://puppetlabs.com/puppet) as
well as for nodes connected to a puppet server. The provisioners are extremely
simple to use and work great. An example of using standalone puppet below:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :puppet
end
{% endhighlight %}

Really! This provisioner actually can run with no configuration just fine. But
you'll probably want to learn more. So check out the [standalone puppet](/docs/provisioners/puppet.html)
and [puppet server](/docs/provisioners/puppet_server.html) docs for more
information.

The `lucid32` and `lucid64` base boxes now have puppet pre-installed as well.

## Gentoo and RedHat Host-Only Networking

[Host-Only Networking](/docs/host_only_networking.html) has up until now been
been restricted to Ubuntu/Debian users. But thanks to work done by [Tino Breddin](http://github.com/tolbrino)
and [Michael Bearne](https://github.com/michaelbearne), Vagrant now supports
Gentoo and RedHat host-only networks as well.

You shouldn't have to do anything special for this to work. Vagrant is
now able to detect what distro of linux your VM has, and uses the appropriate
OS-specific code to manage host only networks.

For more information on host only networks, please [read the documentation](/docs/host_only_networking.html).

## Thanks Contributors!

And finally, thanks so much to 3rd party contributors. Between Vagrant 0.6.0 and
Vagrant 0.7.0, **18** people contributed code to Vagrant, which is by far the
largest between releases ever. Puppet, Gentoo, and RedHat support were all
almost completely done by 3rd party contributors.

## Complete Changelog

As always, the complete changelog can be found at the following URL:

[https://github.com/mitchellh/vagrant/blob/master/CHANGELOG.md](https://github.com/mitchellh/vagrant/blob/master/CHANGELOG.md)
