---
layout: documentation
title: Documentation - Provisioners - Others
---
# Provisioning with Other Tools

Vagrant understands that not everyone uses [Chef](http://www.opscode.com/chef)
or [Puppet](http://www.puppetlabs.com/puppet).

If you use some other configuration management solution, then Vagrant doesn't force you to use Chef or Puppet!
You can easily create your own provisioners by extending the `Vagrant::Provisioners::Base` class and passing that
class as the configured provisioner.

## Creating Your Own Provisioner

The [Chef Solo](/docs/provisioners/chef_solo.html), [Chef Server](/docs/provisioners/chef_server.html), and
[Puppet](/docs/provisioners/puppet.html) provisioners aren't anything special; they simply inherit from the
`Vagrant::Provisioners::Base` class. They are also given a special ruby symbol shortcut
such as `:chef_solo` and `:puppet` since they are built into Vagrant, but thats only for ease of use.

You can create your own provisioner by extending from the base. The
methods you're supposed to implement are `prepare` and `provision!`.
Neither methods take any arguments.

### The `prepare` Method

The `prepare` method can be used to configure any shared folders or to verify
settings. An example implementation of the prepare method is shown below:

{% highlight ruby %}
class FooProvisioner < Vagrant::Provisioners::Base
  def prepare
    # Maybe we need to share a folder?
    env.config.vm.share_folder("foo-folder", "/tmp/foo-provisioning",
                                             "/path/to/host/folder")
  end
end
{% endhighlight %}

### The `provision!` Method

The `provision!` method is called when the VM is ready to be provisioned.
At this point, the VM can be assumed to be booted and running with the
shared folders setup. During this method, the provisioner should SSH and
do any commands it is required to do to provision. An example implementation
is shown below:

{% highlight ruby %}
class FooProvisioner < Vagrant::Provisioners::Base
  def provision!
    env.ssh.execute do |ssh|
      ssh.exec!("sudo foo-provision")
    end
  end
end
{% endhighlight %}

## Custom Configuration

Provisioners often require configuration, such as specifying paths to scripts,
parameters to scripts, etc. Vagrant allows 3rd party provisioners to plug into
the Vagrantfile config mechanism as 1st-class citizens. An example of doing this
is shown below:

{% highlight ruby %}
class FooProvisioner < Vagrant::Provisioners::Base
  # Define the configuration class
  class Config < Vagrant::Config::Base
    attr_accessor :chunky_bacon
  end

  # Register it with Vagrant
  Vagrant::Config.configures :foo, Config
end
{% endhighlight %}

After registering the config such as in the above example, it can be accessed
directly in the Vagrantfile:

{% highlight ruby %}
require 'foo_provisioner'

Vagrant::Config.run do |config|
  config.foo.chunky_bacon = "yes, please"
end
{% endhighlight %}

And finally, within the provisioner itself, this configuration can be used in
both the `prepare` and the `provision!` method:

{% highlight ruby %}
class FooProvisioner < Vagrant::Provisioners::Base
  def provision!
    if env.config.foo.chunky_bacon
      env.logger.info "Chunky bacon is on."
    end
  end
end
{% endhighlight %}

## Enabling and Executing

Telling Vagrant to use your custom provisioner is extremely easy. Assuming
you use the above `FooProvisioner` you simply configure the Vagrantfile like so:

{% highlight ruby %}
require 'foo_provisioner'

Vagrant::Config.run do |config|
  config.vm.provisioner = FooProvisioner
end
{% endhighlight %}

As always, simply running a `vagrant up` or `vagrant reload` at this point
will begin the process.
