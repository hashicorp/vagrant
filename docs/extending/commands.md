---
layout: extending
title: Extending Vagrant - Commands
---
# Commands

Commands are the command-line actions invoked via the `vagrant`
binary or via the `Environment#cli` method if you want to invoke
them programmatically. The plugin API allows you to define new commands
easily. There are two kinds of commands available:

* Single - These are single commands like `vagrant up`.
* Group - These are commands which have subcommands, such as `vagrant box`,
  which has `vagrant box list`, `vagrant box add`, etc.

This page will detail how to create both kinds of commands, which is just
a matter of inheriting from a specific base class and setting some options.

The command API is built on top of [Thor](http://github.com/wycats/thor),
so you automatically get the benefits of command line option parsing, a nice
shell API for colored output and asking for input, etc.

## Single Command

To create a single command, inherit from `Vagrant::Command::Base` and at
the very least, specify a description and register the command with Vagrant.
When this command is executed, _all public methods_ are executed in the order
they're defined, so if you want code that doesn't execute automatically,
be sure to make it `protected` or `private`. An example command `hello` is
shown below:

{% highlight ruby %}
class SayHelloCommand < Vagrant::Command::Base
  register "hello", "Says hello then goodbye"

  def hello
    puts "HELLO!"
  end

  def goodbye
    puts "GOODBYE!"
  end
end
{% endhighlight %}

Important notes:

* The `register` command is **the most important**! It is what registers the
  command with the actual binary. Without this call, the command won't be
  available.

Given the above, the usage and output is shown below:

{% highlight bash %}
$ vagrant hello
HELLO!
GOODBYE!
$
{% endhighlight %}

## Group Command

To create group commands, which are commands with subcommands, inherit from
`Vagrant::Command::GroupBase`. With a group command, each public method is
a separate task. An example is shown below, which is a spin off the above
example, where the "hello" and "goodbye" output is separated into two tasks:

{% highlight ruby %}
class SayCommand < Vagrant::Command::GroupBase
  register "say", "Says either hello or goodbye."

  desc "hello", "Says hello"
  def hello
    puts "HELLO!"
  end

  desc "goodbye", "Says goodbye"
  def goodbye
    puts "GOODBYE!"
  end
end
{% endhighlight %}

Important notes:

* Each individual public method must have a `desc` which describes its
  usage and what the task does.
* The `register` description is given when `vagrant` is called alone or
  when the help is shown.

Given the above, the usage and output is shown below:

{% highlight bash %}
$ vagrant say hello
HELLO!
$ vagrant say goodbye
GOODBYE!
$
{% endhighlight %}
