---
layout: extending
title: Extending Vagrant - Types of Plugins

current: Types of Plugins
---
# Types of Plugins

To be clear, there is only one way of creating plugins, and that is through
Ruby source files. The different "types" of plugins refers to packaging and
usage of the plugins you create. There are two options for this:

* Manually `require`d Ruby files
* RubyGems which are automatically found and loaded by Vagrant

Both options have legitimate pros and cons, and neither should be disregarded
for the other, since it depends on what works best for the problem you're solving.
Details of the methods are below, along with the benefits of each.

## Manually `require`d Ruby Files

The first option is to create a simple Ruby file or files which are then
manually `require`d via a Vagrantfile. For example, if there was a plugin
named "my_plugin" then you could use it like this, assuming the block shown
below is your project Vagrantfile:

{% highlight ruby %}
require 'my_plugin'

Vagrant::Config.run do |config|
  # ...
end
{% endhighlight %}

**Pros:** Very simple, can easily be packaged with your project, explicit in
the Vagrantfile about what is being used.

**Cons:** Repetitive if you're using this plugin all the time, no versioning,
no way to specify dependencies.

## Automatically Loaded RubyGems

The second option is to package your plugin as a RubyGem. If there is a file
named `vagrant_init.rb` somewhere in your gem's load path, then Vagrant
automatically loads it. A typical `vagrant_init.rb` (assumed to be in your
`my_plugin` gem) is shown below. They're usually very simple.

{% highlight ruby %}
# This file is automatically loaded by Vagrant. We use this to kick-start
# our plugin.
require 'my_plugin'

# Perhaps we do some Vagrant-specific stuff here as well, though not in
# this example.
{% endhighlight %}

**Pros:** Automatically available system wide, dependencies are managed by
RubyGems, versioning is available, easy for users to upgrade their plugins.

**Cons:** Implicit loading, not packaged with your project.

Note if you use the gem packaging, the plugin will have to be installed
with Vagrant using the `vagrant gem` command. This is because Vagrant packages
and installers ship with a completely isolated RubyGems installation and never
actually references your global RubyGems installation you may have.
