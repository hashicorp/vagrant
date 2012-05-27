---
layout: extending
title: Extending Vagrant - Commands

current: Commands
---
# Commands

Commands are the command-line actions invoked via the `vagrant`
binary or via the `Environment#cli` method if you want to invoke
them programmatically. The plugin API allows you to define new commands
easily.

Vagrant commands are nothing special. They're simply classes that respond
to a single method `execute` and inherit from `Vagrant::Command::Base`
which provides common extra helpers which assist in error
handling and having your commands behave more "vagrant-like," such as
automatically requiring a VM name in the case of a multi-VM setup.

## A Simple Command

Let's first show a simple example that merely outputs some data to
`stdout`.

{% highlight ruby %}
class SayHelloCommand < Vagrant::Command::Base
  def execute
    puts "HELLO!"
  end
end

Vagrant.commands.register(:hello) { SayHelloCommand }
{% endhighlight %}

Given the above, the usage and output is shown below:

{% highlight bash %}
$ vagrant hello
HELLO!
$
{% endhighlight %}

Notice that writing such a basic command is trivial. Also note the
important step of registering the command. Every command you write must
be registered with Vagrant globally. The name with which you register
the command becomes the command line shortcut to execute the command.
In the above example, we used `hello` as the name. The class of the
command is expected to be the result of a block to the `register`
function. The reason that this is a block is so that you may lazy-load
the class if you want, to improve performance.

## Available Helpers

Some helpers are available when you inherit from `Vagrant::Command::Base`:

* `parse_options` - This parses the arguments of the command against the
  given `OptionParser` instance (a class of Ruby's standard library). This
  will automatically provide help text via the `--help` flag, and will raise
  a human-friendly error in the face of any invalid flags.
* `with_target_vms` - Given a name (or nil), this will yield to the block with
  a `Vagrant::VM` object so you can perform some task on it. This helper makes
  it trivial to seamlessly support both multi-VM and single-VM Vagrant environments.
* `split_main_and_subcommand` - This assists in splitting the arguments to the
  command in order to support further subcommands. This is how commands such as
  `vagrant box add` are implemented.

Note that the best examples of the above helpers can be seen by simply reading
the [source code of the commands that ship with Vagrant](https://github.com/mitchellh/vagrant/tree/master/lib/vagrant/command).
