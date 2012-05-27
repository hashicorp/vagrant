---
layout: v2_documentation
title: Documentation - Using Plugins

current: Plugins
---
# Using Plugins

## Installing Plugins

Vagrant plugins are easy to install and easy to use. Plugins are typically
distributed as a RubyGem, Ruby's packaging system. RubyGems can be installed
with Vagrant using the `vagrant gem` command. For example, if we want to install
the `foo` plugin:

{% highlight bash %}
$ vagrant gem install foo
...
{% endhighlight %}

Some very simple plugins may also be distributed simply as a single blob
of Ruby code. If this is done, you can just paste it into your `Vagrantfile`.

## Enabling Plugins

Once a plugin is installed, you need to enable it. This can be done in one
of two places: a `Vagrantfile` or `.vagrantrc` in your home directory. Enabling
a plugin in a project `Vagrantfile` only enables that plugin for that project,
but also requires that everyone using that project on your team has that
plugin installed. Enabling a plugin in the `.vagrantrc` file in your home
directory enables the plugin for all projects for that user.

Plugins are enabled using the `Vagrant.require_plugin` command:

{% highlight ruby %}
Vagrant.require_plugin "foo"
{% endhighlight %}

`require_plugin` works much like Ruby's built-in `require`, except Vagrant will do some
additional checks and throw human-friendly errors if something fails while
loading the plugin.
