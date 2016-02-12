---
layout: "docs"
page_title: "Custom Provisioners - Plugin Development"
sidebar_current: "plugins-provisioners"
script: |-
  This page documents how to add new provisioners to Vagrant, allowing Vagrant
  to automatically install software and configure software using a custom
  provisioner. Prior to reading this, you should be familiar with the plugin
  development basics.
---

# Plugin Development: Provisioners

This page documents how to add new [provisioners](/docs/provisioning/) to Vagrant,
allowing Vagrant to automatically install software and configure software
using a custom provisioner. Prior to reading this, you should be familiar
with the [plugin development basics](/docs/plugins/development-basics.html).

<div class="alert alert-warning">
  <strong>Warning: Advanced Topic!</strong> Developing plugins is an
  advanced topic that only experienced Vagrant users who are reasonably
  comfortable with Ruby should approach.
</div>

## Definition Component

Within the context of a plugin definition, new provisioners can be defined
like so:

```ruby
provisioner "custom" do
  require_relative "provisioner"
  Provisioner
end
```

Provisioners are defined with the `provisioner` method, which takes a
single argument specifying the name of the provisioner. This is the
name that used with `config.vm.provision` when configuring and enabling
the provisioner. So in the case above, the provisioner would be enabled
using `config.vm.provision :custom`.

The block argument then lazily loads and returns a class that implements
the `Vagrant.plugin(2, :provisioner)` interface, which is covered next.

## Provisioner Class

The provisioner class should subclass and implement
`Vagrant.plugin(2, :provisioner)` which is an upgrade-safe way to let
Vagrant return the proper parent class for provisioners.

This class and the methods that need to be implemented are
[very well documented](https://github.com/mitchellh/vagrant/blob/master/lib/vagrant/plugin/v2/provisioner.rb).
The documentation on the class in the comments should be enough
to understand what needs to be done.

There are two main methods that need to be implemented: the
`configure` method and the `provision` method.

The `configure` method is called early in the machine booting process
to allow the provisioner to define new configuration on the machine, such
as sharing folders, defining networks, etc. As an example, the
[Chef solo provisioner](https://github.com/mitchellh/vagrant/blob/master/plugins/provisioners/chef/provisioner/chef_solo.rb#L24)
uses this to define shared folders.

The `provision` method is called when the machine is booted and ready
for SSH connections. In this method, the provisioner should execute
any commands that need to be executed.
