---
layout: documentation
title: Documentation - Provisioners - Chef Solo

current: Provisioners
---
# Chef Solo Provisioning

**Provisioner key:** `:chef_solo`

[Chef Solo](http://wiki.opscode.com/display/chef/Chef+Solo) allows you to provision your virtual
machine with [Chef Cookbooks](http://wiki.opscode.com/display/chef/Cookbooks) without requiring a
[Chef Server](http://wiki.opscode.com/display/chef/Chef+Server). At a very basic level, [Chef](http://www.opscode.com/chef/)
is an open source systems integration framework which automates tasks through programmable "cookbooks."
This page will not go into the details of creating custom chef cookbooks, since that
is covered in detail around the web, but a good place to start is the
[opscode-cookbooks organization](https://github.com/opscode-cookbooks)
which contains cookbooks for most of the popular server software already made. Note
that sometimes these cookbooks may not work directly
"out of the box," and proper Chef support channels should be used if this occurs,
since they are more knowledgable in general on that topic.

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

You can also specify multiple cookbook paths by making the configuration an
array of file paths. Note that the working directory while running Vagrant will always
be the directory which contains the Vagrantfile, therefore file paths will always
be expanded relative to that working directory.

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = ["cookbooks", "~/company/cookbooks"]
  end
end
{% endhighlight %}

And finally, somewhat of an advanced feature, but also sometimes needed: If
the virtual machine already has cookbooks somewhere inside of it, you may
specific folders _within the virtual machine_ which contain cookbooks using
a special syntax:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = ["cookbooks", [:vm, "/usr/local/cookbooks"]]
  end
end
{% endhighlight %}

The above tells Vagrant that there are cookbooks in the "cookbooks" folder
relative to the project root as well as the "/usr/local/cookbooks" directory
on the virtual machine itself.

## Specifying the Run List

By default, Vagrant has an empty run list, or the list of recipes or roles for
Chef to run. You need to explicitly specify the run list for Vagrant using
some basic configuration:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :chef_solo do |chef|
    chef.add_recipe("apache")
    chef.add_recipe("php")
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

## Data Bags

Chef solo also supports [data bags](http://wiki.opscode.com/display/chef/Data+Bags),
which are arbitrary JSON documents that can be searched and loaded by Chef recipes.
Vagrant exposes this functionality completely as well through similar configuration:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :chef_solo do |chef|
    chef.data_bags_path = "data_bags"
  end
end
{% endhighlight %}

The data bags directory is expected to be the proper layout that Chef expects
and documents.

## Downloading Packaged Cookbooks

Chef solo supports using cookbooks which are [downloaded from a URL](http://wiki.opscode.com/display/chef/Chef+Solo#ChefSolo-RunningfromaURL). You can also do this with Vagrant:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :chef_solo do |chef|
    chef.recipe_url = "http://files.mycompany.com/cookbooks.tar.gz"
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
