---
layout: documentation
title: Documentation - Provisioners - Chef Server
---
# Chef Server Provisioning

[Chef Server](http://wiki.opscode.com/display/chef/Chef+Server) allows you to provision your
virtual machine without having to keep the cookbooks within the repository itself. There are
various benefits to this approach, such as being able to use your production cookbooks from
chef server to provision your development environment.

<div class="info">
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
  config.chef.chef_server_url = "http://mychefserver.com:4000"
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
  config.chef.validation_key_path = "validation.pem"
end
{% endhighlight %}

The path given as the value to the configuration is expanded relative to the project
directory if its a relative path. If its an absolute path, then it is taken as is.

## Specifying the Run List

The [run list](http://wiki.opscode.com/display/chef/Setting+the+run_list+in+JSON)
is the list of things to run on the node, which are recipes and/or
roles. By default, the run list will run the `vagrant_main` recipe. This can easily
be altered using the helpers provided by the config, which are fairly self-explanatory:

{% highlight ruby %}
Vagrant::Config.run do |config|
  # Provision with the apache2 recipe
  config.chef.add_recipe("apache2")

  # Provision with the database role
  config.chef.add_role("database")
end
{% endhighlight %}

However, if you need to access the run list directly, you can also use the
`run_list` accessor:

{% highlight ruby %}
Vagrant::Config.run do |config|
  # Modifying the run list directly
  config.chef.run_list = ["recipe[foo]", "role[bar]"]
end
{% endhighlight %}

## Other Configuration Options

There are other configuration options as well, but these can normally be left
as their default. But if your chef server requires these to be customized, they
are available to you. This documentation won't go into detail of their function
since if you're looking for these you probably already know what they are for:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.chef.validation_client_name = "chef-validator"
  config.chef.client_key_path = "/etc/chef/client.pem"
end
{% endhighlight %}

## Enabling and Executing

Finally, once everything is setup, provisioning can be enabled and run. To enable
provisioning, tell Vagrant to use chef server in the Vagrantfile:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provisioner = :chef_server
end
{% endhighlight %}

Once enabled, if you are building a VM from scratch, run `vagrant up` and provisioning
will automatically occur. If you already have a running VM and don't want to rebuild
everything from scratch, run `vagrant reload` and provisioning will automatically
occur.