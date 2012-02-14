---
layout: documentation
title: Documentation - Provisioners - Puppet Server

current: Provisioners
---
# Puppet Server Provisioning

**Provisioner key:** `:puppet_server`

If you use a [Puppet](http://puppetlabs.com/puppet) server, then Vagrant can
register itself as a node on the server and use the configuration that server
has to configure your virtual machine. If you're just getting started with
Puppet, you should instead be using the standalone [Puppet provisioner](/docs/provisioners/puppet.html).

This page will not go into the details of creating a Puppet server or Puppet
manifests, since that is covered in detail around the web, but a good place to
start is the [Puppet Labs Docs site](http://docs.puppetlabs.com).

## Setting the Puppet Server

Vagrant needs to know the name of your Puppet server. By default, Vagrant will
look for a server called `puppet`. You can override this in your Vagrantfile
using the `puppet_server` option.

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
    puppet.options = ["--user","puppet"]
  end
end
{% endhighlight %}

You can also pass options as strings:

{% highlight ruby %}
  config.vm.provision :puppet_server, :options = "--verbose --debug"
{% endhighlight %}
