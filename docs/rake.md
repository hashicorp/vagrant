---
layout: documentation
title: Documentation - Rake Integration

current: Rake Integration
---
# Rake Integration

Sometimes the commands Vagrant provides aren't enough. Maybe you need
a command that shuts down the system gracefully, or a command that makes
sure that before starting up some files are in place, or _anything_.

Luckily, Vagrant is coded in such a way that extending it via rake
tasks isn't too hard! Being completely honest, allowing for this sort of
extensibility wasn't an initial design goal, but was a positive side
effect from Vagrant's modular design. After seeing the possibilities
this provides, we've decided future versions of Vagrant will attempt to
provide developers with more tools to ease the process of extending
Vagrant. For now, however, its still completely possible to power Vagrant
through Rake or any other Ruby-based script.

## Loading Vagrant

Vagrant is loaded like any other Ruby library. At the top of the Rakefile
or Ruby script being made to control Vagrant, load the library:

{% highlight ruby %}
require 'vagrant'
{% endhighlight %}

**Note:** Depending how your system is setup, you may need to `require 'rubygems'`
as well.

## Loading the Vagrant Environment

The first step to doing anything with Vagrant is to make sure that the
environment is loaded. Each Vagrant project has its own "environment"
which simply encapsulates the configuration, SSH access, VM, etc.
of that project.

Loading the environment sets up all the paths, loads the virtual
machine (if one exists), and loads the configuration. Loading the
environment for the current directory is a one-liner:

{% highlight ruby %}
env = Vagrant::Environment.new
{% endhighlight %}

If you're working in a separate directory or you're writing a script that
will be used with multiple Vagrant projects, you can load a specific
Vagrant environment by passing in a path:

{% highlight ruby %}
env = Vagrant::Environment.new(:cwd => "/path/to/my/project")
{% endhighlight %}

## Executing Commands

All available `vagrant` command line tools are available in code through
the `cli` method on the environment instance. This allows you to
easily to run the command line tools in the context of an environment
without any extra fuss. The following is a simple rake task that simply
does the equivalent of `vagrant up` but does some extra, useless things
around it:

{% highlight ruby %}
# Example of emulating vagrant up with some code around it
task :up do
  puts "About to run vagrant-up..."
  env = Vagrant::Environment.new
  env.cli("up")
  puts "Finished running vagrant-up"
end
{% endhighlight %}

The arguments to `subcommand` are simply an array of parameters
that you'd typically sent to the command line client, ignoring the `vagrant`
part. This allows you to do more complex things easily:

{% highlight ruby %}
desc "Package my environment with a custom file"
task :package do
  env = Vagrant::Environment.new
  env.cli("package", "--include", "MyCustomFile")
end
{% endhighlight %}

## SSH Commands

Perhaps you want to write a rake task that does some commands within the
virtual server setup? This can be done through the `channel` accessor of any
VM within the environment which provides a communication channel to execute
commands within the virtual machine.

The following example is a useful example showing how to create a graceful
shutdown command:

{% highlight ruby %}
task :graceful_down do
  env = Vagrant::Environment.new
  raise "Must run `vagrant up`" if !env.primary_vm.created?
  raise "Must be running!" if env.primary_vm.state != :running
  env.primary_vm.channel.sudo("halt")
end
{% endhighlight %}

Additionally, if you're in a [multi-VM environment](/docs/multivm.html), you can
access the VMs through the `vms` array on the environment:

{% highlight ruby %}
task :graceful_down do
  env = Vagrant::Environment.new
  env.vms.each do |vm|
    vm.channel.sudo("halt")
  end
end
{% endhighlight %}
