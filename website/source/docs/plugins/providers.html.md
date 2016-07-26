---
layout: "docs"
page_title: "Custom Providers - Plugin Development"
sidebar_current: "plugins-providers"
description: |-
  This page documents how to add support for new providers to Vagrant, allowing
  Vagrant to run and manage machines powered by a system other than VirtualBox.
  Prior to reading this, you should be familiar with the plugin development
  basics.
---

# Plugin Development: Providers

This page documents how to add support for new [providers](/docs/providers/)
to Vagrant, allowing Vagrant to run and manage machines powered by a
system other than VirtualBox. Prior to reading this, you should be familiar
with the [plugin development basics](/docs/plugins/development-basics.html).

Prior to developing a provider you should also be familiar with how
[providers work](/docs/providers/) from
a user standpoint.

<div class="alert alert-warning">
  <strong>Warning: Advanced Topic!</strong> Developing plugins is an
  advanced topic that only experienced Vagrant users who are reasonably
  comfortable with Ruby should approach.
</div>

## Example Provider: AWS

The best way to learn how to write a provider is to see how one is
written in practice. To augment this documentation, please heavily
study the [vagrant-aws](https://github.com/mitchellh/vagrant-aws) plugin,
which implements an AWS provider. The plugin is a good example of how to
structure, test, and implement your plugin.

## Definition Component

Within the context of a plugin definition, new providers are defined
like so:

```ruby
provider "my_cloud" do
  require_relative "provider"
  Provider
end
```

Providers are defined with the `provider` method, which takes a single
argument specifying the name of the provider. This is the name that is
used with `vagrant up` to specify the provider. So in the case above,
our provider would be used by calling `vagrant up --provider=my_cloud`.

The block argument then lazily loads and returns a class that
implements the `Vagrant.plugin(2, :provider)` interface, which is covered
next.

## Provider Class

The provider class should subclass and implement
`Vagrant.plugin(2, :provider)` which is an upgrade-safe way to let Vagrant
return the proper parent class.

This class and the methods that need to be implemented are
[very well documented](https://github.com/mitchellh/vagrant/blob/master/lib/vagrant/plugin/v2/provider.rb). The documentation done on the class in the comments should be
enough to understand what needs to be done.

Viewing the [AWS provider class](https://github.com/mitchellh/vagrant-aws/blob/master/lib/vagrant-aws/provider.rb) as well as the
[overall structure of the plugin](https://github.com/mitchellh/vagrant-aws) is recommended as a strong getting started point.

Instead of going in depth over each method that needs to be implemented,
the documentation will cover high-level but important points to help you
create your provider.

## Box Format

Each provider is responsible for having its own box format. This is
actually an extremely simple step due to how generic boxes are. Before
explaining you should get familiar with the general
[box file format](/docs/boxes/format.html).

The only requirement for your box format is that the `metadata.json`
file have a `provider` key which matches the name of your provider you
chose above.

In addition to this, you may put any data in the metadata as well
as any files in the archive. Since Vagrant core itself does not care,
it is up to your provider to handle the data of the box. Vagrant core
just handles unpacking and verifying the box is for the proper
provider.

As an example of a couple box formats that are actually in use:

* The `virtualbox` box format is just a flat directory of the contents
  of a `VBoxManage export` command.

* The `vmware_fusion` box format is just a flat directory of the
  contents of a `vmwarevm` folder, but only including the bare essential
  files for VMware to function.

* The `aws` box format is just a Vagrantfile defaulting some configuration.
  You can see an [example aws box unpacked here](https://github.com/mitchellh/vagrant-aws/tree/master/example_box).

Before anything with your provider is even written, you can verify
your box format works by doing `vagrant box add` with it. When you do
a `vagrant box list` you can see what boxes for what providers are installed.

You do _not need_ the provider plugin installed to add a box for that
provider.

<a name="actions"></a>
## Actions

Probably the most important concept to understand when building a
provider is the provider "action" interface. It is the secret sauce that
makes providers do the magic they do.

Actions are built on top of the concept of
[middleware](https://github.com/mitchellh/middleware), which
allow providers to execute multiple distinct steps, have error recovery
mechanics, as well as before/after behaviors, and much more.

Vagrant core requests specific actions from your provider through the
`action` method on your provider class. The full list of actions requested
is listed in the comments of that method on the superclass. If your
provider does not implement a certain action, then Vagrant core will show
a friendly error, so do not worry if you miss any, things will not explode
or crash spectacularly.

Take a look at how the VirtualBox provider
[uses actions to build up complicated multi-step processes](https://github.com/mitchellh/vagrant/blob/master/plugins/providers/virtualbox/action.rb#L287). The AWS provider [uses a similar process](https://github.com/mitchellh/vagrant-aws/blob/master/lib/vagrant-aws/action.rb).

## Built-in Middleware

To assist with common tasks, Vagrant ships with a set of
[built-in middleware](https://github.com/mitchellh/vagrant/tree/master/lib/vagrant/action/builtin). Each of the middleware is well commented on the behavior and options
for each, and using these built-in middleware is critical to building
a well-behaved provider.

These built-in middleware can be thought of as a standard library for
your actions on your provider. The core VirtualBox provider uses these
built-in middleware heavily.

## Persisting State

In the process of creating and managing a machine, providers generally need
to store some sort of state somewhere. Vagrant provides each machine with
a directory to store this state.

As a use-case example for this, the VirtualBox provider stores the UUID
of the VirtualBox virtual machine created. This allows the provider to track
whether the machine is created, running, suspended, etc.

The VMware provider actually copies the entire virtual machine into this
state directory, complete with virtual disk drives and everything.

The directory is available from the `data_dir` attribute of the `Machine`
instance given to initialize your provider. Within middleware actions, the
machine is always available via the `:machine` key on the environment. The
`data_dir` attribute is a Ruby [Pathname](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/pathname/rdoc/Pathname.html) object.

It is important for providers to carefully manage all the contents of
this directory. Vagrant core itself does little to clean up this directory.
Therefore, when a machine is destroyed, be sure to clean up all the state
from this directory.

## Configuration

Vagrant supports [provider-specific configuration](/docs/providers/configuration.html),
allowing for users to finely tune and control specific providers from
Vagrantfiles. It is easy for your custom provider to expose custom configuration
as well.

Provider-specific configuration is a special case of a normal
[configuration plugin](/docs/plugins/configuration.html). When defining the
configuration component, name the configuration the same as the provider,
and as a second parameter, specify `:provider`, like so:

```
config("my_cloud", :provider) do
  require_relative "config"
  Config
end
```

As long as the name matches your provider, and the second `:provider`
parameter is given, Vagrant will automatically expose this as provider-specific
configuration for your provider. Users can now do the following in their
Vagrantfiles:

```
config.vm.provider :my_cloud do |config|
  # Your specific configuration!
end
```

The configuration class returned from the `config` component in the plugin
is the same as any other [configuration plugin](/docs/plugins/configuration.html),
so read that page for more information. Vagrant automatically handles
configuration validation and such just like any other configuration piece.

The provider-specific configuration is available on the machine object
via the `provider_config` attribute. So within actions or your provider class,
you can access the config via `machine.provider_config`.

<div class="alert alert-info">
  <strong>Best practice:</strong> Your provider should <em>not require</em>
  provider-specific configuration to function, if possible. Vagrant
  practices a strong <a href="https://en.wikipedia.org/wiki/Convention_over_configuration">convention over configuration</a>
  philosophy. When a user installs your provider, they should ideally
  be able to <code>vagrant up --provider=your_provider</code> and
  have it just work.
</div>

## Parallelization

Vagrant supports parallelizing some actions, such as `vagrant up`, if the
provider explicitly supports it. By default, Vagrant will not parallelize a
provider.

When parallelization is enabled, multiple [actions](#actions) may be run
in parallel. Therefore, providers must be certain that their action stacks
are thread-safe. The core of Vagrant itself (such as box collections, SSH,
etc.) is thread-safe.

Providers can explicitly enable parallelization by setting the `parallel`
option on the provider component:

```ruby
provider("my_cloud", parallel: true) do
  require_relative "provider"
  Provider
end
```

That is the only change that is needed to enable parallelization.
