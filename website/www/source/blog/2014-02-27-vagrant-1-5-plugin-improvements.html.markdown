---
page_title: "Vagrant 1.5 Plugin Development Improvements"
title: "Plugin Development Improvements in Vagrant 1.5"
author: "Mitchell Hashimoto"
author_url: https://github.com/mitchellh
---

Vagrant has a vibrant plugin community. We're always looking
to improve the life of a plugin developer through better abstractions,
documentation, and more. In Vagrant 1.5, we made some big improvements
that should make developing plugins much, much nicer.

With Vagrant 1.1, we both helped and hurt plugin development. Plugin
development improved because plugins became a first class supported
concept with the `vagrant plugin` command and much of the core dogfooding
the API.

But plugin development was hurt because Vagrant switched to
an installer-only model, breaking many plugin development environments
and causing some frustrating edge cases.

With Vagrant 1.5, we've made some big changes that should make the
life of a plugin developer much more enjoyable. Read on to find out more.

READMORE

### Real Dependency Resolution

In prior versions of Vagrant, there was no real dependency resolution
done for plugins. Dependency resolution is the process by which all
the dependencies of a set of components are inspected, and results in
the order and versions of components that must be loaded so that all
components properly work together.

To make this concrete, we can use an example from Vagrant 1.4, where
no dependency resolution took place:

* Plugin A depends on "foo >= 1.0, < 1.5".
* Plugin B depends on "foo = 1.1"
* When Plugin A is loaded, it would load the latest version satisfying
  its constraints. This might be "foo 1.4".
* When Plugin B is loaded, it would try to load "foo 1.1" but since
  "foo 1.4" is already loaded, it would fail!

The frustrating part of this failure is that it should _never happen_.
Plugin A should've loaded "foo 1.1" because it still satisfies its constraints
while also allowing Plugin B to load.

With Vagrant 1.5, Vagrant performs real dependency resolution. The effect
of this is twofold. First, in the scenario above, both plugin A and plugin B would load and
everything would _just work_.

Next, if the user attempts to install a plugin that can't be loaded because
it would create an unsolvable dependency conflict, then the user
will see an error at _install time_, and the plugin will fail to install.
Additionally, the user will be notified what dependencies conflict and
in what plugins.

### Bundler Support

Prior to Vagrant 1.5, Vagrant loaded plugins out of its own internal gem
directory. Because of this, plugin development was slightly awkward since
Vagrant wouldn't load your plugins from your `Gemfile`. As a result, plugin
developers had to create Vagrantfiles that manually did a `require` of all plugins
they needed.

Now, Vagrant 1.5 will automatically load any gems in the "plugins" group
in your `Gemfile`. As an example, here is the `Gemfile` for a "vagrant-bar"
plugin:

<pre class="prettyprint">
source "https://rubygems.org"

group :development do
  gem "vagrant",
    git: "https://github.com/mitchellh/vagrant.git"
end

group :plugins do
  gem "vagrant-foo",
  gem "vagrant-bar", path: "."
end
</pre>

With the above, Vagrant will automatically load both "vagrant-bar" and
"vagrant-foo" plugins. Because of the `path: "."` option for "vagrant-bar",
it will use the plugin in that directory, allowing you to make changes
and instantly see changes.

You no longer need to do any `Vagrant.require_plugin` silliness in your
Vagrantfiles in order to activate your plugin.

### API Compatibility

We're improving our promise on API compatibility. Prior to Vagrant 1.5,
we had no promise of API compatibility except at major versions (1.0, 2.0,
etc.). Because these versions are so far apart, we're making our promise stronger.

With Vagrant 1.5, we promise to not break API compatibility of internals
_between_ minor versions. For example, if your plugin works with 1.5.0,
it should work with a potential 1.5.7 months later. However, it is
_not_ promised to work with Vagrant 1.6.

Given this, it actually becomes quite easy to remain API compatible. As an
example, the [Vagrant VMware](/vmware) plugin is compatible back to
Vagrant 1.1. This is done through various code branching that looks like
the following:

<pre class="prettyprint lang-ruby">
if Vagrant::VERSION < "1.5.0"
  # Compatibility layer
else
  # New stuff available
end
</pre>

If we break your plugin between minor versions, we'll treat it like a bug
so please report it as such.

### New Functionality

In addition to these major improvements, we've introduced some great
new functionality that plugin developers can take advantage of in Vagrant 1.5.

**Provider capabilities** allow providers to opt-in to provider-specific
functionality. Plugins can query whether the provider supports a certain
functionality and behave accordingly. As an example use case, the recently
announced [Vagrant Share](/blog/feature-preview-vagrant-1-5-share.html)
functionality uses a provider-capability `read_ip_address` to ask
providers for an accessible IP address to the machine.

**New built-in middleware** such as `IsState` and `Message` remove a lot
of boilerplate from implementing new providers.

**A new internal class** `Vagrant::Vagrantfile` allows plugins to load
Vagrantfiles and request `Vagrant::Machine` objects from that Vagrantfile
outside of the default root Vagrantfile that is part of a
`Vagrant::Environment`.

And much, much more.

### Future Improvements

We're constantly interested in improving plugin development for Vagrant
since it is a core part of what makes Vagrant successful. We have some
improvements planned but if you see anything you want improved, please
help us out by letting us know!
