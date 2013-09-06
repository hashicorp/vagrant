---
page_title: "Packaging and Distribution - Plugin Development"
sidebar_current: "plugins-packaging"
---

# Plugin Development: Packaging & Distribution

This page documents how to add new commands to Vagrant, invokable.
This page documents how to organize the file structure of your plugin
and distribute it so that it is installable using
[standard installation methods](/v2/plugins/usage.html).
Prior to reading this, you should be familiar
with the [plugin development basics](/v2/plugins/development-basics.html).

<div class="alert alert-warn">
	<p>
		<strong>Warning: Advanced Topic!</strong> Developing plugins is an
		advanced topic that only experienced Vagrant users who are reasonably
		comfortable with Ruby should approach.
	</p>
</div>

## Example Plugin

The best way to describe packaging and distribution is to look at
how another plugin does it. The best example plugin available for this
is [vagrant-aws](https://github.com/mitchellh/vagrant-aws).

By using [Bundler](http://gembundler.com) and Rake, building a new
vagrant-aws package is easy. By simply calling `rake package`, a
`gem` file is dropped into the directory. By calling `rake release`,
the gem is built and it is uploaded to the central [RubyGems](http://rubygems.org)
repository so that it can be installed using `vagrant plugin install`.

Your plugin can and should be this easy, too, since you basically
get this for free by using Bundler.

## Setting Up Your Project

To setup your project, run `bundle gem vagrant-my-plugin`. This will create a
`vagrant-my-plugin` directory that has the initial layout to be a RubyGem.

You should modify the `vagrant-my-plugin.gemspec` file to add any
dependencies and change any metadata. View the [vagrant-aws.gemspec](https://github.com/mitchellh/vagrant-aws/blob/master/vagrant-aws.gemspec)
for a good example.

<div class="alert alert-warn">
	<p>
		<strong>Do not depend on Vagrant</strong> for your gem. Vagrant
		is no longer distributed as a gem, and you can assume that it will
		always be available when your plugin is installed.
	</p>
</div>

Next, create a `Rakefile` that has at the very least, the following
contents:

```ruby
require 'rubygems'
require 'bundler/setup'
Bundler::GemHelper.install_tasks
```

If you run `rake -T` now, which lists all the available rake tasks,
you should see that you have the `package` and `release` tasks. You
can now develop your plugin and build it!

You can view the [vagrant-aws Rakefile](https://github.com/mitchellh/vagrant-aws/blob/master/Rakefile)
for a more comprehensive example that includes testing.

## Testing Your Plugin

You have a couple options for testing your plugin. First, you can run
`rake package`, then `vagrant plugin install` the resulting file to
test it. The downside of this is that there is a pretty slow feedback
loop every time you want to test the plugin.

Alternatively, you can depend on Vagrant from your Gemfile for development
purposes only. Then you can use `bundle exec vagrant` and a Vagrantfile
in your own directory to test it. This has a fast feedback loop, but requires
that Vagrant has all the dependencies it needs installed on your system.

vagrant-aws uses the second option. You can see the dependency in the
[Gemfile](https://github.com/mitchellh/vagrant-aws/blob/master/Gemfile).
The Vagrantfile is gitignored so that sensitive and volatile test
information can be put into it. The important bit is that the Vagrantfile
must have a `Vagrant.require_plugin` call so that it is loaded, since
Vagrant doesn't automatically know about plugins not installed using
`vagrant plugin`.

For example, a vagrant-aws development Vagrantfile might look like this:

```ruby
Vagrant.require_plugin "vagrant-aws"

Vagrant.configure("2") do |config|
  config.vm.box = "test"
end
```

Then you can run `bundle exec vagrant up` to test it. Note the "bundle exec"
is required so that Bundler uses the proper Vagrant installation.
