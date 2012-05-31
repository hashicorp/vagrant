---
layout: v2_documentation
title: Documentation - Writing Plugins - Plugin Definition

section: plugins
current: Definition
---
# Plugin Definition

The most important part of a plugin is the plugin definition. This is a
class which contains metadata (name, author, etc.) about the plugin as
well as configures the various parts of the plugin. An example plugin
definition is shown below, and then we'll go through each part:

{% highlight ruby %}
class MyPlugin < Vagrant.plugin("1")
  name "my-plugin"
  description "This plugin just adds a new command."

  activated do
    require "my_command"
  end

  command("foo") { MyCommand }
end
{% endhighlight %}

Let's go over each part individually.

## Class Definition

The first part is creating a class that inherits from the proper
plugin superclass. In our example, that is this line:

{% highlight ruby %}
class MyPlugin < Vagrant.plugin("1")
{% endhighlight %}

The name of the class itself is not important, just make sure it is
unique. The superclass bit is extremely important. `Vagrant.plugin("1")`
returns the proper superclass to inherit from, and the argument specifies
the plugin interface version you want to use. The plugin interface version
will increase with each major version of Vagrant, and is meant as a way to
maintain backwards compatibility with plugins.

Future versions of Vagrant will always be able to load past plugin
version definitions, so Vagrant version 2 can load Vagrant version 1 plugin
definitions. This is so that when upgrading a major version of Vagrant,
past plugins don't cause crashes. Note that the functionality of past plugin
versions will _not_ be backwards compatible with future major releases of Vagrant,
so a plugin written for Vagrant 1 will not work with Vagrant 2, but the definition
will still load.

## Plugin Metadata

The next part of the definition is some plugin metadata:

{% highlight ruby %}
name "my-plugin"
description "This plugin just adds a new command."
{% endhighlight %}

The `name` is important and is required. A plugin will not work without
a name. The description is optional and remains unused currently, though
in the future it is likely that some sort of plugin listing interface
will use this.

More metadata fields may be added in the future.

## Activation Callback

Next is the activation callback, which is an **extremely important** piece
of the plugin definition:

{% highlight ruby %}
activated do
  require "my_command"
end
{% endhighlight %}

As mentioned earlier, plugin _definitions_ will always be backwards
compatible with future versions of Vagrant, but the plugin components themselves
will not be. Because of this, loading the individual plugin components early
can cause your plugin to crash Vagrant in future major versions. Instead,
loading of various components should be deferred until Vagrant _activates_ a
plugin. The `activated` block is called when Vagrant decides to use the plugin,
meaning that the plugin is compatible with that version of Vagrant, so it is
safe to load your components here.

In our example, we use the activated block to load our command class from
a file "my_command." If we had loaded this at the top of the Ruby file or anywhere
else, future versions of Vagrant would crash since the custom command
interface would surely have changed.

## Component Registration

Finally, we register the various components of the plugin. This tells Vagrant
what the plugin does. In our basic example, we registered a new command "foo"
which can be invoked with `vagrant foo`:

{% highlight ruby %}
command("foo") { MyCommand }
{% endhighlight %}

Each component may have a slightly differing registration process, so please
see the documentation for that specific item you're trying to write for
more information. However, you should see that it is pretty simple Ruby.
If you're not familiar with Ruby, the only odd thing may be the `{ MyCommand }`
at the end. This is a Ruby block, and is basically a callback parameter.

Most components use a callback to get the main logic associated with it so
that future versions of Vagrant can still read the plugin definition without
crashing from incompatible component APIs. For example, in future versions of
Vagrant, the base class for commands might change. If we passed `MyCommand`
as a direct parameter, even reading the plugin definition class would crash
the program. By making it a callback, it is lazily evaluated, and as such
as long as the plugin definition API remains the same (which it will), then
future versions of Vagrant won't crash from loading prior plugin versions.
