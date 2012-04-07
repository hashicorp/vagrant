---
layout: documentation
title: Documentation - Provisioners - Chef Server

current: Provisioners
---
# Chef Server Provisioning

**Provisioner key:** `:chef_server`

[Chef Server](http://wiki.opscode.com/display/chef/Chef+Server) allows you to provision your
virtual machine without having to keep the cookbooks within the repository itself. There are
various benefits to this approach, such as being able to use your production cookbooks from
chef server to provision your development environment.

<div class="alert alert-block alert-notice">
  <h3>Do you really need a chef server?</h3>
  <p>
    If you're unfamiliar with <a href="http://www.opscode.com/chef/">Chef</a> or if you're
    just getting started with it, a chef server is probably a bit too much for what you need,
    for now. In this case, you should use <a href="/docs/provisioners/chef_solo.html">Chef Solo</a>
    provisioning to start, then move on to chef server later.
  </p>
</div>

## Setting the Chef Server URL

The first step to provisioning with chef server is to tell Vagrant where the chef
server is located. This is done below:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :chef_client do |chef|
    chef.chef_server_url = "http://mychefserver.com:4000"
  end
end
{% endhighlight %}

## Setting the Validation Key Path

Chef server uses keypairs in order to verify and register nodes to the chef server
(similar to SSH key-based authentication). The validation key is used by an unregistered
client to verify itself and register with the chef server. Vagrant needs to know
the path to this validation key in order to configure the client for chef server. This
is also set in the Vagrantfile:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :chef_client do |chef|
    chef.validation_key_path = "validation.pem"
  end
end
{% endhighlight %}

The path given as the value to the configuration is expanded relative to the project
directory if its a relative path. If its an absolute path, then it is taken as is.

## Specifying the Run List

The [run list](http://wiki.opscode.com/display/chef/Setting+the+run_list+in+JSON)
is the list of things to run on the node, which are recipes and/or roles.
Usually the run list is managed by the chef server. In this case, you don't have
to do anything, since by default Vagrant will pull the run list from the chef
server. But if you wish, you can specify the run list directly by using the
helpers provided by the config, which are fairly self-explanatory:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :chef_client do |chef|
    # Provision with the apache2 recipe
    chef.add_recipe("apache2")

    # Provision with the database role
    chef.add_role("database")
  end
end
{% endhighlight %}

If you need to access the run list directly, you can also use the `run_list`
accessor:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :chef_client do |chef|
    # Modifying the run list directly
    chef.run_list = ["recipe[foo]", "role[bar]"]
  end
end
{% endhighlight %}

## Specifying the Environment

If you're using Chef 0.10 or later, you have access to
[environments](http://wiki.opscode.com/display/chef/Environments).
If you'd like to configure the environment you're node is part of, simply
use the `environment` configuration option:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :chef_client do |chef|
    # Set the environment for the chef server
    chef.environment = "development"
  end
end
{% endhighlight %}

## Other Configuration Options

There are other configuration options as well, but these can normally be left
as their default. But if your chef server requires these to be customized, they
are available to you. This documentation won't go into detail of their function
since if you're looking for these you probably already know what they are for:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :chef_client do |chef|
    chef.validation_client_name = "chef-validator"
    chef.client_key_path = "/etc/chef/client.pem"
  end
end
{% endhighlight %}

## Cleanup

When you provision your Vagrant virtual machine with Chef server, it creates a
new [Chef Node](http://wiki.opscode.com/display/chef/Nodes) entry and
[Chef Client](http://wiki.opscode.com/display/chef/Chef+Client)
entry on the Chef server, using the hostname of the machine (e.g.,
`vagrant-ubuntu-oneiric`). After you tear down your virtual machine, you must
explicitly delete these entries from the Chef server before you provision a
new one with Chef server. For example, using knife:

{% highlight bash %}
$ knife node delete vagrant-ubuntu-oneiric
$ knife client delete vagrant-ubuntu-oneiric
{% endhighlight %}

If you fail to do so, you will get the following error when trying to
provision a new virtual machine with the same hostname:

{% highlight bash %}
HTTP Request Returned 409 Conflict: Client already exists.
{% endhighlight %}
