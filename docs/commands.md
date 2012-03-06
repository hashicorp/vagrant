---
layout: documentation
title: Documentation - Commands

current: Commands
---
# Commands

Almost all interaction with Vagrant is via the `vagrant` application on
the command line. `vagrant` has many other subcommands that are invoked
through it, such as `vagrant up` and `vagrant package`.

If you run `vagrant` by itself, it will output all of the available
commands, as well as some usage information.

## Built-in Help

You can quickly and easily get help for any given command by simply adding the
`--help` flag to any command. This will save you the trip of coming to
this documentation page most of the time. Example:

{% highlight bash %}
$ vagrant up --help
Usage: vagrant up [vm-name] [--[no-]provision] [-h]

        --[no-]provision             Enable or disable provisioning
        --provision-with x,y,z       Enable only certain provisioners, by type.
    -h, --help                       Print this help
{% endhighlight %}

