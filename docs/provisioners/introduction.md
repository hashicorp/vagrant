---
layout: documentation
title: Documentation - Provisioners - Introduction
---
# Introduction to Provisioners in Vagrant

Provisioning allows you to use a configuration management tool such as
[Chef](http://opscode.com/chef), [Puppet](http://puppetlabs.com/puppet), or
[your own](/docs/provisioners/others.html) to setup your virtual machine
with everything it needs to run including users, software, and their
respective configuration.

Provisioning of course is completely optional. If you choose to want to
do everything by hand, that is your choice. But provisioning is an important
part of making VM creation repeatable, and the scripts made for provisioning
can typically be used to setup production machines quickly as well.

The provisioner-specific configuration is left to their respective pages,
but this page will introduce how to enable and configure provisioners, and
also some advanced features on provisioner usage.

## Enabling a Provisioner

To enable a provisioner, the `config.vm.provision` method is used. For
example, below we enable the `:chef_solo` provisioner:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :chef_solo
end
{% endhighlight %}

## Configuring a Provisioner

Besides enabling a provisioner, perhaps more important is configuring
it. There are a couple options for configuring the provisioner, and they
may be used in conjunction.

For basic key-value options, you can simply append a hash when enabling
a provisioner, and this will set the configuration values properly:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :chef_solo, :cookbooks_path => "cookbooks", :run_list => "recipe[foo]"
end
{% endhighlight %}

However, some provisioners, such as the chef one, provide nice methods
for assisting with configuration. To use these, we must use a Ruby
block, which is something like a callback. The equivalent to the above,
but using a block, and setting the run list with the helper method instead
of directly:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = "cookbooks"
    chef.add_recipe "foo"
  end
end
{% endhighlight %}

Both are equivalent, and both can be used together, but they both have
their pros and cons.

## Running a Provisioner

Provisioning is automatically run during the `vagrant up` and `vagrant reload`
methods. Additionally, you can call `vagrant provision` on an already
created and running VM to simply run the provisioner, potentially
saving a lot of shut down and boot up time.
