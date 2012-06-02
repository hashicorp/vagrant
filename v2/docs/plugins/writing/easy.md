---
layout: v2_documentation
title: Documentation - Writing Plugins - Easy Plugins

section: plugins
current: Easy Plugins
---
# Easy Plugins

Although plugins are very powerful, they expect at least a slightly
intermediate level of Ruby knowledge. _Easy plugins_ allow people with
very basic Ruby knowledge to write plugins which are able to do the most
common tasks by sacrificing a bit of power and flexibility. If you're just
writing your first plugin, you should first try to write it as an easy plugin
and see if that satisfies your requirements before attempting to write a
full-featured plugin.

Before writing easy plugins, you should be comfortable with
[plugin definitions](/v2/docs/plugins/writing/definition.html).

## Easy Commands

Easy commands provide a way to easily add new commands to the `vagrant`
command line interface. For example, if you want to execute `make` tasks
on a remote server, you could make `vagrant make` with easy commands. The full
working example for `vagrant make` is shown below, and each part will be
covered individually after the code.

{% highlight ruby %}
class VagrantMake < Vagrant.plugin("1")
  name "vagrant-make"

  easy_command "make" do |api|
    task = api.arg_extra
    api.run("cd /vagrant && make #{task}")
  end
end
{% endhighlight %}

Ignoring the plugin definition, the entire logic is implemented in only
two lines of code! The easy command component is registered using the
`easy_command` method. This method takes the command name, which is how
it will be invoked with `vagrant`, along with a Ruby block that takes a
single parameter `api` which has the easy command API.

The documentation for the easy command API can
[be found here](http://rubydoc.info/github/mitchellh/vagrant/master/Vagrant/Easy/CommandAPI).

As you can see, easy commands take away much of the boilerplate associated
with creating a [traditional custom command](/v2/docs/plugins/writing/commands.html),
allowing you to focus on the logic of your command with minimal Ruby knowledge.

**Multi-VM**: Easy commands work with multi-VM as well. With the above
example, if we had a Vagrant environment that defined two virtual machines:
`web` and `db`, we could run `make` on the DB machine by calling
`vagrant make db`. If we wanted to run a specific make task, then we can
do that too: `vagrant make db -- test`. The command comes after a `--` because
the plugin uses `arg_extra` which evalutes to the arguments after the `--`.

## Easy Hooks

Vagrant has a feature called action hooks which allow plugins to hook into
the middle of various actions such as VM booting, provisioning, networking,
etc. It is a very powerful system itself, but the most common case is that
a user wants to add some basic logic between two parts of some process like
`vagrant up`. Easy hooks provide an easy way to hook into these action
sequences. As an example, let's hook into the VM booting process to create
a file in our home directory after it boots. This isn't very useful, but
should highlight what is possible. Just as before, the full working example
is shown below, followed by explanation of individual sections.

{% highlight ruby %}
class VagrantTouchFile < Vagrant.plugin("1")
  name "touch-file"
end
{% endhighlight %}

TODO
