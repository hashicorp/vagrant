---
layout: documentation
title: Changes - 0.1.x to 0.2.x
---
# Changes from Version 0.1.x to 0.2.x

Vagrant `0.1.x` was the first public release of Vagrant and it allowed us to get feedback from users of where
they'd like to see it head. It also allowed us to focus on stability and
cross-platform support, since initially it was only known to run on Mac OS X 10.6,
but Vagrant `0.1.4` now runs on multiple platforms.

This page will outline the major changes from `0.1.x` to `0.2.x`, starting
with the backwards incompatible changes.

## Backwards Incompatible Changes

**Vagrant no longer supports password-based SSH.** Initially, Vagrant _only_
allowed for password based SSH, but Vagrant now _only_ supports key-based
authentication. Most users will need to update their base box to support this,
which is very simple. Read more in the [key-based SSH authentication](#key-based-ssh) section.

**Provisioning Configuration Changed.** If you were using chef solo provisioning
in `0.1.x`, it now must be enabled with `config.vm.provisioners = :chef_solo`.
This is because `config.chef.enabled` no longer exists. Read more about this in the
[multiple provisioner support](#multiple-provisioners) section.

<a name="key-based-ssh"> </a>
## Public/Private Key SSH. No more password SSH support.

While addressing many of the issues users were having getting Vagrant working,
we continually ran into the problem of users not having the `expect` dependency,
which was used for us to SSH via passwords (for `vagrant ssh`). Additionally,
this sort of dependency does not exist natively for Windows, which we would like
to support as well.

We therefore decided to drop support for password SSH completely and only support
SSH via keypairs. This has the benefit of being much simpler for us to program
into Vagrant, and is also much simpler for base box creators to easily setup
their boxes for Vagrant by using the Vagrant insecure keys.

Vagrant now includes two [insecure keys](http://github.com/mitchellh/vagrant/tree/master/keys/) which can be used
to authenticate to public boxes. Public boxes should allow SSH access to the `vagrant`
user via the public insecure key, and Vagrant by default will use the private
insecure key to attempt to access a virtual machine. For more information on
converting boxes to use the new SSH authentication, read the [converting box to key-based SSH](/docs/converting_password_to_key_ssh.html) page.

For users who require more security, they are welcome to use their own keypair
with their box. Vagrant has the `config.ssh.private_key_path` configuration for
just that reason. By setting that to a different private key, Vagrant will
attempt to use that to SSH, instead.

<a name="multiple-provisioners"> </a>
## Multiple Provisioners Support

In Vagrant `0.1.x`, if you wanted provisioning support, you were forced to use
chef solo. In `0.2.x`, Vagrant allows you to use anything you desire, since new provisioners
can be created by subclassing `Vagrant::Provisioners::Base`.

Provisioners are now specified via the `config.vm.provisioners` configuration.
There are symbol shortcuts for the built-in provisioners, but by setting this to
a class which subclasses `Vagrant::Provisioners::Base`, Vagrant will use this instead.

This opens up the possibility for tools like Puppet in addition to Chef.

This means that if you were using chef solo before, you must now enable it like so:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provisioner = :chef_solo
end
{% endhighlight %}

For more information on the new provisioners, read the detailed [provisioners](/docs/provisioners.html) section.

<a name="enhanced-chef-support"> </a>
## Enhanced Chef Support, including Chef Server Support

### Chef Solo Changes

For Chef Solo, Vagrant now supports multiple cookbooks paths by setting
`config.chef.cookbooks_path` to an array of paths.

### Chef Server Support

In addition to Chef Solo, Vagrant now comes with support for Chef Server built-in.
Exact details on how to use chef server with Vagrant are explained on the
[chef server provisioning](/docs/provisioners/chef_server.html) page.

<a name="port-collision-detection"> </a>
## Port Collision Detection

Vagrant will now give an error if it detects that the configured forwarded ports
would collide with another running virtual machine's forwarded ports. Before this
feature, this would fail silently, causing unexpected behavior such as the
VM successfully running but the forwarded port going to some other VM.

<a name="vm-customization"> </a>
## VM Customization

You can now customize the specs and details of the virtual machine via the
_vm customization_ configuration. This allows you to modify details such as the
RAM or name of the VM. It is passed in the complete [VirtualBox::VM](http://mitchellh.github.com/virtualbox/VirtualBox/VM.html) object, so
you're free to modify anything with it. Example below:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.customize do |vm|
    vm.name = "my vagrant VM"
    vm.memory = 512
  end
end
{% endhighlight %}
