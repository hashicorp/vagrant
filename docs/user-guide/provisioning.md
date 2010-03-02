---
layout: guide
title: User Guide - Provisioning
---
# Provisioning

Vagrant supports provisioning a project's VM with [chef](http://www.opscode.com/chef/),
since simply spinning up a blank virtual machine is not very useful! At a very basic level, [chef](http://www.opscode.com/chef/)
is an open source systems integration framework which automates tasks through programmable "cookbooks."
This page will not go into the details of creating custom chef cookbooks, since that
is covered in detail around the web, but a good place to start is the [opscode cookbooks repository](http://github.com/opscode/cookbooks)
which contains cookbooks for most of the popular server software already made.

By default, Vagrant disables provisioning, simply because a couple preparations must be
made prior to provisioning a vagrant environment. Once it is enabled, provisioning
becomes part of the `vagrant up` or `vagrant reload` routine. There is no special provisioning
command to run!

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

## Configuring the Main Cookbook

When chef is run on the virtual system, a single cookbook is executed. This cookbook
is known as the "vagrant main cookbook" and is analogous to the main entry point
of an executable program. This main cookbook should include other cookbooks in the
order they should be run to setup the system.

By default, Vagrant is configured to use the `vagrant_main` cookbook as the main
cookbook. An example main cookbook recipe is embedded below:

{% highlight ruby %}
#
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
  config.chef.json[:recipes] = ["custom_entry_cookbook"]
end
{% endhighlight %}

## JSON Configuration

Every chef cookbook has access to the `node` variable which is a hash containing
server-specific configuration options which can be used to control provisioning.
By default, Vagrant JSON configuration looks like the following:

{% highlight ruby %}
{
  :instance_role => "vagrant",
  :project_directory => "/vagrant", # Or wherever your project directory is setup
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
provisioning, set the flag in the Vagrantfile:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.chef.enabled = true
end
{% endhighlight %}

Once enabled, if you are building a VM from scratch, run `vagrant up` and provisioning
will automatically occur. If you already have a running VM and don't want to rebuild
everything from scratch, run `vagrant reload` and provisioning will automatically
occur.