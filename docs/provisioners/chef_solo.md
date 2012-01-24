---
layout: documentation
title: Documentation - Provisioners - Chef Solo
---
# Chef Solo Provisioning

[Chef Solo](http://wiki.opscode.com/display/chef/Chef+Solo) allows you to provision your virtual
machine with [Chef Cookbooks](http://wiki.opscode.com/display/chef/Cookbooks) without requiring a
[Chef Server](http://wiki.opscode.com/display/chef/Chef+Server). At a very basic level, [chef](http://www.opscode.com/chef/)
is an open source systems integration framework which automates tasks through programmable "cookbooks."
This page will not go into the details of creating custom chef cookbooks, since that
is covered in detail around the web, but a good place to start is the [opscode cookbooks repository](http://github.com/opscode/cookbooks)
which contains cookbooks for most of the popular server software already made.

## Setting the Cookbooks Path

First, Vagrant needs to know where the cookbooks are located. By default, Vagrant will
look in the "cookbooks" directory relative to the root of the project directory (where
a project's Vagrantfile is). The cookbooks directory should have a structure similar to
the following:

{% highlight bash %}
$ ls cookbooks/
apache2/
passenger_apache2/
rails/
sqlite/
vagrant_main/
{% endhighlight %}

Basically, the cookbooks directory should immediately contain all the folders of the
various cookbooks.

To tell Vagrant what the cookbook path is, set it up in your Vagrantfile, like so:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :chef_solo do |chef|
    # This path will be expanded relative to the project directory
    chef.cookbooks_path = "cookbooks"
  end
end
{% endhighlight %}

<div class="alert-message block-message grey notice">
  <h3>Multiple Cookbook Paths</h3>
  <p>
    You can also specify multiple cookbook paths by making the configuration an
    array of file paths. Note that the working directory while running Vagrant will always
    be the directory which contains the Vagrantfile, therefore file paths will always
    be expanded relative to that working directory.

<pre>
Vagrant::Config.run do |config|
  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = ["cookbooks", "~/company/cookbooks"]
  end
end
</pre>
  </p>
</div>

## Configuring the Main Cookbook

By default, Vagrant has an empty run list, or the list of recipes or roles for
Chef to run. We've setup a `vagrant_main` cookbook above which we'll make our
entrypoint. The default recipe for this cookbook is shown below:

{% highlight ruby %}
# vagrant_main cookbook
# This cookbook includes and sets up a server with apache, mysql,
# rails, and passenger.
#
require_recipe "apache2"
require_recipe "mysql"
require_recipe "rails"
require_recipe "passenger_apache2::mod_rails"
{% endhighlight %}

Then, we must tell Vagrant to use this cookbook:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :chef_solo do |chef|
    chef.add_recipe("vagrant_main")
  end
end
{% endhighlight %}

## JSON Configuration

Every chef cookbook has access to the `node` variable which is a hash containing
server-specific configuration options which can be used to control provisioning.
By default, Vagrant JSON configuration looks like the following:

{% highlight javascript %}
{
  :instance_role => "vagrant",
  :vagrant => {
    :config => { ... }, # Full Vagrant config
  }
}
{% endhighlight %}

This JSON configuration is specifically thought out such that the `instance_role`
key could be used so that cookbooks could be shared between production and development,
possibly tweaking paths or configuration based on the `instance_role`.

But sometimes, cookbooks need additional, custom JSON configuration. For this
you can specify additional JSON data in the Vagrantfile:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :chef_solo do |chef|
    chef.json = {
      :load_limit => 42,
      :chunky_bacon => true
    })
  end
end
{% endhighlight %}

## Roles

Chef solo supports [roles](http://wiki.opscode.com/display/chef/Roles), which are specified via
JSON files within a roles directory. Similar to the cookbooks path, a roles path can be specified
to a directory containing these role files, and these roles can then be used by the
chef solo run list. An example of configuring roles is shown below:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :chef_solo do |chef|
    # The roles path will be expanded relative to the project directory
    chef.roles_path = "roles"
    chef.add_role("web")
  end
end
{% endhighlight %}

## Configuring the Temporary Path

In order to run chef, Vagrant has to mount the specified cookbooks directory as a
shared folder on the virtual machine. By default, this is set to be `/tmp/vagrant-chef`,
and this should be fine for most users. But in the case that you need to customize
the location, you can do so in the Vagrantfile:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :chef_solo do |chef|
    chef.provisioning_path = "/tmp/vagrant-chef"
  end
end
{% endhighlight %}

This folder is created for provisioning purposes and destroyed once provisioning
is complete.

## Enabling and Executing

By calling `config.vm.provision` with `:chef_solo`, chef solo based provisioning
will be enabled and ran during a VM setup. If you are building a VM from scratch,
run `vagrant up` and provisioning will automatically occur. If you already have
a running VM and don't want to rebuild everything from scratch, run `vagrant reload`
and it will restart the VM, without completely destroying the environment first,
allowing the import step to be skipped.
