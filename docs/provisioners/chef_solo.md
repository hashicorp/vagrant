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
Vagrant::Configure.run do |config|
  # This path will be expanded relative to the project directory
  config.chef.cookbooks_path = "cookbooks"
end
{% endhighlight %}

<div class="info">
  <h3>Multiple Cookbook Paths</h3>
  <p>
    You can also specify multiple cookbook paths by making the configuration an
    array of file paths. Every file path will be expanded relative to the project
    directory, and chef solo will then look in every directory for the cookbooks.

{% highlight ruby %}
Vagrant::Configure.run do |config|
  config.chef.cookbooks_path = ["cookbooks", "~/company/cookbooks"]
end
{% endhighlight %}
  </p>
</div>

## Configuring the Main Cookbook

By default, Vagrant is configured to run a single cookbook called `vagrant_main`.
This cookbook is known as the "vagrant main cookbook" and is analogous to the
main entry point of an executable program. This main cookbook should include
other cookbooks in the order they should be run to setup the system.

An example `vagrant_main` default recipe file is shown below:

{% highlight ruby %}
# vagrant_main cookbook
# This cookbook includes and sets up a server with apache, mysql,
# rails, and passenger. It finally runs a custom cookbook to configure
# the application.
#
require_recipe "apache2"
require_recipe "mysql"
require_recipe "rails"
require_recipe "passenger_apache2::mod_rails"
require_recipe "my_custom_application"
{% endhighlight %}

If you want Vagrant to use a cookbook other than `vagrant_main` as the default,
this can be changed using the Vagrantfile:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.chef.run_list.clear
  config.chef.add_recipe("my_recipe")
end
{% endhighlight %}

<div class="info">
  <h3>Why the main cookbook at all?</h3>
  <p>
    Some people ask, "Why does Vagrant default to the vagrant_main cookbook at all?"
    The reason is that its more portable to require all recipes within a single cookbook
    than to define them all using <code>add_recipe</code> in the Vagrantfile. By
    requiring all the recipes in a single meta-cookbook, you can then reuse that cookbook
    for production environments and so on. Vagrant is basically encouraging you
    to write more portable cookbooks!
  </p>
  <p>
    Of course, if you don't like this, you're free to define your own recipes
    as shown above.
  </p>
</div>

## JSON Configuration

Every chef cookbook has access to the `node` variable which is a hash containing
server-specific configuration options which can be used to control provisioning.
By default, Vagrant JSON configuration looks like the following:

{% highlight ruby %}
{
  :instance_role => "vagrant",
  :vagrant => {
    :config => { ... }, # Full Vagrant config
    :directory => "/vagrant" # Or wherever configured project directory is
  }
}
{% endhighlight %}

This JSON configuration is specifically thought out such that the `instance_role`
key could be used so that cookbooks could be shared between production and development,
possibly tweaking paths or configuration based on the `instance_role`. And
`project_directory` is useful if you're setting up a VirtualHost for a web server,
for example, and need to set the path to the public directory within your
`project_directory`.

But sometimes, cookbooks need additional, custom JSON configuration. For this
you can specify additional JSON data in the Vagrantfile:

{% highlight ruby %}
Vagrant::Configure.run do |config|
  # merge is used to preserve the default JSON configuration, otherwise it'll
  # all be overwritten
  config.chef.json.merge!({
    :load_limit => 42,
    :chunky_bacon => true
  })
end
{% endhighlight %}

## Configuring the Server Path

In order to run chef, Vagrant has to mount the specified cookbooks directory as a
shared folder on the virtual machine. By default, this is set to be `/tmp/vagrant-chef`,
and this should be fine for most users. But in the case that you need to customize
the location, you can do so in the Vagrantfile:

{% highlight ruby %}
Vagrant::Configure.run do |config|
  config.chef.provisioning_path = "/tmp/vagrant-chef"
end
{% endhighlight %}

This folder is created for provisioning purposes and destroyed once provisioning
is complete.

## Enabling and Executing

Finally, once everything is setup, provisioning can be enabled and run. To enable
provisioning, tell Vagrant to use chef solo in the Vagrantfile:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provisioner = :chef_solo
end
{% endhighlight %}

Once enabled, if you are building a VM from scratch, run `vagrant up` and provisioning
will automatically occur. If you already have a running VM and don't want to rebuild
everything from scratch, run `vagrant reload` and it will restart the VM, without completely
destroying the environment first, allowing the import step to be skipped.