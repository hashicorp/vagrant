---
layout: "docs"
page_title: "Packaging and Distribution - Plugin Development"
sidebar_current: "plugins-packaging"
description: |-
  This page documents how to organize the file structure of your plugin
  and distribute it so that it is installable using standard installation
  methods. Prior to reading this, you should be familiar with the plugin
  development basics.
---

# Plugin Development: Packaging & Distribution

This page documents how to organize the file structure of your plugin
and distribute it so that it is installable using
[standard installation methods](/docs/plugins/usage.html).
Prior to reading this, you should be familiar
with the [plugin development basics](/docs/plugins/development-basics.html).

<div class="alert alert-warning">
  <strong>Warning: Advanced Topic!</strong> Developing plugins is an
  advanced topic that only experienced Vagrant users who are reasonably
  comfortable with Ruby should approach.
</div>

## Example Plugin

The best way to describe packaging and distribution is to look at
how another plugin does it. The best example plugin available for this
is [vagrant-aws](https://github.com/mitchellh/vagrant-aws).

By using [Bundler](http://bundler.io) and Rake, building a new
vagrant-aws package is easy. By simply calling `rake package`, a
`gem` file is dropped into the directory. By calling `rake release`,
the gem is built and it is uploaded to the central [RubyGems](https://rubygems.org)
repository so that it can be installed using `vagrant plugin install`.

Your plugin can and should be this easy, too, since you basically
get this for free by using Bundler.

## Setting Up Your Project

To setup your project, run `bundle gem vagrant-my-plugin`. This will create a
`vagrant-my-plugin` directory that has the initial layout to be a RubyGem.

You should modify the `vagrant-my-plugin.gemspec` file to add any
dependencies and change any metadata. View the [vagrant-aws.gemspec](https://github.com/mitchellh/vagrant-aws/blob/master/vagrant-aws.gemspec)
for a good example.

<div class="alert alert-warning">
  <p>
    <strong>Do not depend on Vagrant</strong> for your gem. Vagrant
    is no longer distributed as a gem, and you can assume that it will
    always be available when your plugin is installed.
  </p>
</div>

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

Next, create a `Rakefile` that has at the very least, the following
contents:

```ruby
require "rubygems"
require "bundler/setup"
Bundler::GemHelper.install_tasks
```

If you run `rake -T` now, which lists all the available rake tasks,
you should see that you have the `package` and `release` tasks. You
can now develop your plugin and build it!

You can view the [vagrant-aws Rakefile](https://github.com/mitchellh/vagrant-aws/blob/master/Rakefile)
for a more comprehensive example that includes testing.

## Testing Your Plugin

To manually test your plugin during development, use
`bundle exec vagrant` to execute Vagrant with your plugin loaded
(thanks to the Gemfile setup we did earlier).

For automated testing, the
[vagrant-spec](https://github.com/mitchellh/vagrant-spec)
project provides helpers for both unit and acceptance testing
plugins. See the giant README for that project for a detailed
description of how to integrate vagrant-spec into your project.
Vagrant itself (and all of its core plugins) use vagrant-spec
for automated testing.
