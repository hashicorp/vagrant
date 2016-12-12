---
layout: "docs"
page_title: "Plugin Development Basics - Plugins"
sidebar_current: "plugins-development-basics"
description: |-
  Plugins are a great way to augment or change the behavior and functionality
  of Vagrant. Since plugins introduce additional external dependencies for
  users, they should be used as a last resort when attempting to
  do something with Vagrant.
---

# Plugin Development Basics

Plugins are a great way to augment or change the behavior and functionality
of Vagrant. Since plugins introduce additional external dependencies for
users, they should be used as a last resort when attempting to
do something with Vagrant.

But if you need to introduce custom behaviors
into Vagrant, plugins are the best way, since they are safe against future
upgrades and use a stable API.

<div class="alert alert-warning">
  <strong>Warning: Advanced Topic!</strong> Developing plugins is an
  advanced topic that only experienced Vagrant users who are reasonably
  comfortable with Ruby should approach.
</div>

Plugins are written using [Ruby](https://www.ruby-lang.org/en/) and are packaged
using [RubyGems](https://rubygems.org/). Familiarity with Ruby is required,
but the [packaging and distribution](/docs/plugins/packaging.html) section should help
guide you to packaging your plugin into a RubyGem.

## Setup and Workflow

Because plugins are packaged as RubyGems, Vagrant plugins should be
developed as if you were developing a regular RubyGem. The easiest
way to do this is to use the `bundle gem` command.

Once the directory structure for a RubyGem is setup, you will want
to modify your Gemfile. Here is the basic structure of a Gemfile for
Vagrant plugin development:

```ruby
source "https://rubygems.org"

group :development do
  gem "vagrant", git: "https://github.com/mitchellh/vagrant.git"
end

group :plugins do
  gem "my-vagrant-plugin", path: "."
end
```

This Gemfile gets "vagrant" for development. This allows you to
`bundle exec vagrant` to run Vagrant with your plugin already loaded,
so that you can test it manually that way.

The only thing about this Gemfile that may stand out as odd is the
"plugins" group and putting your plugin in that group. Because
`vagrant plugin` commands do not work in development, this is how
you "install" your plugin into Vagrant. Vagrant will automatically
load any gems listed in the "plugins" group. Note that this also
allows you to add multiple plugins to Vagrant for development, if
your plugin works with another plugin.

When you want to manually test your plugin, use
`bundle exec vagrant` in order to run Vagrant with your plugin
loaded (as we specified in the Gemfile).

## Plugin Definition

All plugins are required to have a definition. A definition contains details
about the plugin such as the name of it and what components it contains.

A definition at the bare minimum looks like the following:

```ruby
class MyPlugin < Vagrant.plugin("2")
  name "My Plugin"
end
```

A definition is a class that inherits from `Vagrant.plugin("2")`. The "2"
there is the version that the plugin is valid for. API stability is only
promised for each major version of Vagrant, so this is important. (The
1.x series is working towards 2.0, so the API version is "2")

**The most critical feature of a plugin definition** is that it must _always_
load, no matter what version of Vagrant is running. Theoretically, Vagrant
version 87 (does not actually exist) would be able to load a version 2 plugin
definition. This is achieved through clever lazy loading of individual components
of the plugin, and is covered shortly.

## Plugin Components

Within the definition, a plugin advertises what components it adds to
Vagrant. An example is shown below where a command and provisioner are
added:

```
class MyPlugin < Vagrant.plugin("2")
  name "My Plugin"

  command "run-my-plugin" do
    require_relative "command"
    Command
  end

  provisioner "my-provisioner" do
    require_relative "provisioner"
    Provisioner
  end
end
```

Let us go over the major pieces of what is going on here. Note from a general
Ruby language perspective the above _should_ be familiar. The syntax should
not scare you. If it does, then please familiarize with Ruby further before
attempting to write a plugin.

The first thing to note is that individual components are defined by
making a method call with the component name, such as `command` or
`provisioner`. These in turn take some parameters. In the case of our
example it is just the name of the command and the name of the provisioner.
All component definitions then take a block argument (a callback) that
must return the actual component implementation class.

The block argument is where the "clever lazy loading" (mentioned above)
comes into play. The component blocks should lazy load the actual file that
contains the implementation of the component, and then return that component.

This is done because the actual dependencies and APIs used when defining
components are not stable across major Vagrant versions. A command implementation
written for Vagrant 2.0 will not be compatible with Vagrant 3.0 and so on. But
the _definition_ is just plain Ruby that must always be forward compatible
to future Vagrant versions.

To repeat, **the lazy loading aspect of plugin components is critical**
to the way Vagrant plugins work. All components must be lazily loaded
and returned within their definition blocks.

Now, each component has a different API. Please visit the relevant section
using the navigation to the left under "Plugins" to learn more about developing
each type of component.

## Error Handling

One of Vagrant's biggest strength is gracefully handling errors and reporting
them in human-readable ways. Vagrant has always strongly believed that if
a user sees a stack trace, it is a bug. It is expected that plugins will behave
the same way, and Vagrant provides strong error handling mechanisms to
assist with this.

Error handling in Vagrant is done entirely by raising Ruby exceptions.
But Vagrant treats certain errors differently than others. If an error
is raised that inherits from `Vagrant::Errors::VagrantError`, then the
`vagrant` command will output the message of the error in nice red text
to the console and exit with an exit status of 1.

Otherwise, Vagrant reports an "unexpected error" that should be reported
as a bug, and shows a full stack trace and other ugliness. Any stack traces
should be considered bugs.

Therefore, to fit into Vagrant's error handling mechanisms, subclass
`VagrantError` and set a proper message on your exception. To see
examples of this, look at Vagrant's [built-in errors](https://github.com/mitchellh/vagrant/blob/master/lib/vagrant/errors.rb).

## Console Input and Output

Most plugins are likely going to want to do some sort of input/output.
Plugins should _never_ use Ruby's built-in `puts` or `gets` style methods.
Instead, all input/output should go through some sort of Vagrant UI object.
The Vagrant UI object properly handles cases where there is no TTY, output
pipes are closed, there is no input pipe, etc.

A UI object is available on every `Vagrant::Environment` via the `ui` property
and is exposed within every middleware environment via the `:ui` key. UI
objects have [decent documentation](https://github.com/mitchellh/vagrant/blob/master/lib/vagrant/ui.rb)
within the comments of their source.
