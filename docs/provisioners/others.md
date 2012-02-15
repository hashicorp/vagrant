---
layout: documentation
title: Documentation - Provisioners - Others

current: Provisioners
---
# Provisioning with Other Tools

Although Vagrant ships standard with some of the most popular provisioning
options, there will always be new tools and other options that are used.
Vagrant allows for custom provisioners to easily be written and used in
place or alongside the built-in ones. To use a custom provisioner, some
Ruby knowledge is necessary.

Custom provisioners are created by inheriting a class from `Vagrant::Provisioners::Base`
and using that class as the provisioner.

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
settings. When `prepare` is called, the virtual machine may or may not be
running, so no communication should be done. Instead, the goal of the method
is for any additional configuration or validation that needs to be done.
An example implementation of the prepare method is shown below:

{% highlight ruby %}
class FooProvisioner < Vagrant::Provisioners::Base
  def prepare
    # Maybe we need to share a folder?
    env[:vm].config.vm.share_folder("foo-folder", "/tmp/foo-provisioning",
                                                  "/path/to/host/folder")
  end
end
{% endhighlight %}

### The `provision!` Method

The `provision!` method is called when the VM is ready to be provisioned.
At this point, the VM can be assumed to be booted and running with the
shared folders setup. During this method, the provisioner should SSH and
run any commands it requires for provisioning. An example implementation
is shown below:

{% highlight ruby %}
class FooProvisioner < Vagrant::Provisioners::Base
  def provision!
    env[:vm].channel.execute("sudo foo-provision")
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
  class Config < Vagrant::Config::Base
    attr_accessor :chunky_bacon
  end

  def self.config_class
    Config
  end
end
{% endhighlight %}

Vagrant calls the class-level `config_class` method on the provisioner to
ask the provisioner for the configuration class. In the above case, the
inner `Config` class is returned to Vagrant. Once Vagrant knows about the
configuration class, it is able to be used just like any other provisioner:

{% highlight ruby %}
require 'foo_provisioner'

Vagrant::Config.run do |config|
  config.vm.provision FooProvisioner do |foo|
    foo.chunky_bacon = "yes, please"
  end
end
{% endhighlight %}

And finally, within the provisioner itself, this configuration can be used in
both the `prepare` and the `provision!` method:

{% highlight ruby %}
class FooProvisioner < Vagrant::Provisioners::Base
  def provision!
    if config.foo.chunky_bacon
      env.ui.info "Chunky bacon is on."
    end
  end
end
{% endhighlight %}

<div class="alert alert-block alert-notice">
  <h3>`env.config` versus `config`</h3>
  <p>
    In the example towards the top, we used <code>env.config</code>, but directly
    above we used <code>config</code>. What's the difference? <code>env.config</code>
    refers to the global config for the VM from the Vagrantfile. <code>config</code>
    fefers only to the provisioner-specific configuration.
  </p>
</div>

## Enabling and Executing

Telling Vagrant to use your custom provisioner is extremely easy. Assuming
you use the above `FooProvisioner` in a file "foo_provisioner.rb" you
simply configure the Vagrantfile like so:

{% highlight ruby %}
require 'foo_provisioner'

Vagrant::Config.run do |config|
  config.vm.provision FooProvisioner
end
{% endhighlight %}

As always, simply running a `vagrant up` or `vagrant reload` at this point
will begin the process.
