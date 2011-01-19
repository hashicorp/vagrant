---
layout: documentation
title: Documentation - Provisioners - Puppet Server
---
# Puppet Server Provisioning

[Puppet](http://www.puppetlabs.com/puppet) allows you to provision your virtual machines with Puppet manifests. It requires a
Puppet server and node confguration for your VM on that server.

This page will not go into the details of creating a Puppet server or Puppet manifests, since that
is covered in detail around the web, but a good place to start is the [Puppet Labs Docs site](http://docs.puppetlabs.com).

## Setting the Puppet Server option

To configure Vagrant to use the Puppet Server provisioner, enable the it like so:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :puppet_server
end
{% endhighlight %}

However, some options are required before this will actually work. Read on to
learn about these options and how to set them.

## Setting the Puppet Server

Vagrant needs to know the name of your Puppet server.  By default, Vagrant will look for a server called
`puppet`. You can override this in your Vagrantfile using the `puppet_server` option.

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :puppet_server do |puppet|
    puppet.puppet_server = "puppet.example.com"
  end
end
{% endhighlight %}

Here we've specified the Puppet Server as `puppet.example.com`.

## Configuring the node name

We can also control the name of the node which is passed to the Puppet Server. Remember this is important because Puppet uses this
node name to identify both the configuration to be applied and to generate an SSL certificate to authenticate the node to the Puppet Server.  The node name defaults to the name of the box being provisioned.

You can control the node name with the `puppet_node` option like so:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :puppet_server do |puppet|
    puppet.puppet_server = "puppet.example.com"
    puppet.puppet_node = "vm.example.com"
  end
end
{% endhighlight %}

# Setting options

You can also specify additional options to be passed to the Puppet Server using the `options` variable.

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :puppet_server do |puppet|
    config.puppet_server.options = ["--user","puppet"]
  end
end
{% endhighlight %}

You can also pass options as strings:

{% highlight ruby %}
  config.vm.provision :puppet_server, :options = "--verbose --debug"
{% endhighlight %}

# Executing

Once enabled and configuration, if you are building a VM from scratch, run `vagrant up` and provisioning
will automatically occur. If you already have a running VM and don't want to rebuild
everything from scratch, run `vagrant reload` and it will restart the VM, without completely
destroying the environment first, allowing the import step to be skipped.

Remember that running `vagrant reload` or `vagrant provision` will attempt to re-run the Puppet agent. If the
agent is already then this will return an error. To re-provision the host restart the Puppet agent on the VM using the
binary or init script.
