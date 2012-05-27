---
layout: documentation
title: Changes - 0.3.x to 0.4.x
---
# Changes in Vagrant 0.4.x

## VirtualBox 3.2 Support

Vagrant now supports VirtualBox 3.2.x in addition to the 3.1.x series.
No configuration is necessary; Vagrant will automatically determine which
VirtualBox version is running and use the correct API calls.

## Multi-VM Environments

Vagrant can now automate and manage multiple VMs to represent a single
project. This allows developers to model more complex server setups on
their development machine. A very basic multi-VM Vagrantfile is shown
below:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.define :web do |web_config|
    web_config.vm.box = "web"
    web_config.vm.forward_port("http", 80, 8080)
  end

  config.vm.define :db do |db_config|
    db_config.vm.box = "db"
    db_config.vm.forward_port("db", 3306, 3306)
  end
end
{% endhighlight %}

For more information, please read the page on [multi-VM environments](/docs/multivm.html).

## Host Only Networking

Prior to 0.4.x, Vagrant could only forward ports via a NAT connection.
Vagrant now allows VMs to specify a static IP for themselves, which
can be accessed on the host machine or any other VMs on the same
host only network. This feature can work hand in hand with the multi-VM
feature announced above to provide efficient internal networking between
VMs. An example of assigning a static IP to a VM is shown below:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.network("192.168.10.10")
end
{% endhighlight %}

For more information, read the page on [host only networking](/docs/host_only_networking.html).

## Automatic Port Collision Fixes

Since version 0.2.0, Vagrant has reported any potential port collisions
for forwarded ports. This was typically a rare occurence which only cropped
up when multiple Vagrant environments were running at the same time. With
the introduction of multi-VM support, port collision is now quite common.
To deal with this, Vagrant can now automatically resolve any port collisions
which are detected.

For an example and more information, please view the `config.vm.forward_port`
documentation on the [Vagrantfile page](/docs/vagrantfile.html#config-vm-forwardport).

## New Abstraction: Systems

"Systems" are a new abstraction within Vagrant which allow OS or system
specific behaviour such as shutdown or mounting folders to be defined within
a specific system class, which is then configured within the Vagrantfile.
Vagrant ships with a general Linux system which should cover the majority
of users and is the default system.

For more information, please read the [systems documentation](/docs/systems.html).

## Minor Changes

### `vagrant provision`

`vagrant provision` can now be called at any time to simply run the provisioning
scripts without having to reload the entire VM environment. There are certain
limitations to this command which are discussed further on the commands
documentation page.

### Relative Path Shared Folders

The host path for a shared folder can now be a relative path. This relative
path will be expanded relative to where the project Vagrantfile is. Example
below shows how the root shared folder is defined:

{% highlight ruby %}
config.vm.share_folder("v-root", "/vagrant", ".")
{% endhighlight %}

### Many Bug Fixes

As always, a handful of bugs have been fixed since Vagrant 0.3.0.
