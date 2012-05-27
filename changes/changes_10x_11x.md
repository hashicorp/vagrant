---
layout: default
title: Changes - 1.0.x to 1.1.x
---

<h1 class="top">Changes from Vagrant 1.0.x to 1.1.x</h1>

Vagrant 1.0 was the first stable release of Vagrant. The 1.0.x series
will continue to be supported for some time and 1.1.x marks the first release
on the experimental path towards Vagrant 2.0. I recommend reading about the
[Vagrant versioning scheme](/version_scheme.html) for more information on
how Vagrant versioning works.

Vagrant 1.1 is mostly foundational work towards some of the more radical
changes coming in future versions of Vagrant, and doesn't introduce any
major new features, except the vastly improved plugin interface. Additionally,
Vagrant 1.1 contains improvements and bug fixes that weren't critical enough
to be backported to 1.0.x.

The major highlight of Vagrant 1.1 is that Vagrant now has a completely
revamped and improved plugin system. In fact, the new plugin system is so
powerful that much of the core of Vagrant is
[built using plugins](https://github.com/mitchellh/vagrant/tree/master/plugins).
Therefore, much of the changes mentioned below will be in regards to plugins.

## No More Auto-discovery of Plugins

Vagrant no longer automatically discovers and loads plugins.
In prior versions of Vagrant, if you used VeeWee, then after a gem install
VeeWee magically worked with Vagrant. This auto-discovery and loading has
been disabled since it caused such a performance impact on Vagrant. Removing
this feature has improved the responsiveness of `vagrant` by at least 50%
on bare installs, and much more on installs with plugins installed.

Instead, plugins must now be explicitly loaded using `Vagrant.require_plugin`
either in your Vagrantfile or in a `.vagrantrc` file in your home directory.

## Versioned Plugins

All plugins must now define themselves by inheriting from a class returned
by `Vagrant.plugin`. For example:

{% highlight ruby %}
class MyPlugin < Vagrant.plugin("1")
  name "foo"
end
{% endhighlight %}

You may notice the `"1"` passed to `Vagrant.plugin`. This is the version of
the plugin interface you're requesting. Vagrant will use this to provide backwards
compatibility for plugins in all future versions. Note that the _functionality_
will not be backwards compatible. That is, plugins from version 1 will not work
with version 2 of Vagrant. However, plugin definitions will not crash version 2,
and Vagrant will be able to show a nice error or warning message that certain
plugins will not work. This is much improved from the current system of mostly
crashing in the face of internal API changes.

## Easy Plugins

The power of plugins come at a cost: they require a decent amount of Ruby
knowledge. To combat this requirement, easy plugins were created which make
it dead easy to achieve the most common tasks in plugins. Easy plugins don't
have the full power of regular plugins, but allow you to quickly get started
with plugins, and make it very easy to change to full featured plugins later.
The following is an example of an easy plugin:

{% highlight ruby %}
class MyPlugin < Vagrant.plugin("1")
  name "my plugin"

  # This command runs the "run-tests" program in the /vagrant directory
  # within the VM. Just run `vagrant test`
  easy_command "test" do |ops|
    ops.run("cd /vagrant && ./run-tests")
  end
end
{% endhighlight %}

For more information, check out the [full documentation on easy plugins](#).
