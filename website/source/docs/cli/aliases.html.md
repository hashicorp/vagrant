---
layout: "docs"
page_title: "Aliases - Command-Line Interface"
sidebar_current: "cli-aliases"
description: |-
  Custom Vagrant commands can be defined using aliases, allowing for a simpler,
  easier, and more familiar command line interface.
---

# Aliases

Inspired in part by Git's own
[alias functionality](https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases),
aliases make your Vagrant experience simpler, easier, and more familiar by
allowing you to create your own custom Vagrant commands.

Aliases can be defined within `VAGRANT_HOME/aliases` file, or in a custom file
defined using the `VAGRANT_ALIAS_FILE` environment variable, in the following
format:

```
# basic command-level aliases
start = up
stop = halt

# advanced command-line aliases
eradicate = !vagrant destroy && rm -rf .vagrant
```

In a nutshell, aliases are defined using a standard `key = value` format, where
the `key` is the new Vagrant command, and the `value` is the aliased command.
Using this format, there are two types of aliases that can be defined: internal
and external aliases.

## Internal Aliases

Internal command aliases call the CLI class directly, allowing you to alias
one Vagrant command to another Vagrant command. This technique can be very
useful for creating commands that you think _should_ exist. For example,
if `vagrant stop` feels more intuitive than `vagrant halt`, the following alias
definitions would make that change possible:

```
stop = halt
```

This makes the following commands equivalent:

```
vagrant stop
vagrant halt
```

## External Aliases

While internal aliases can be used to define more intuitive Vagrant commands,
external command aliases are used to define Vagrant commands with brand new
functionality. These aliases are prefixed with the `!` character, which
indicates to the interpreter that the alias should be executed as a shell
command. For example, let's say that you want to be able to view the processor
and memory utilization of the active project's virtual machine. To do this, you
could define a `vagrant metrics` command that returns the required information
in an easy-to-read format, like so:

```
metrics = !ps aux | grep "[V]BoxHeadless" | grep $(cat .vagrant/machines/default/virtualbox/id) | awk '{ printf("CPU: %.02f%%, Memory: %.02f%%", $3, $4) }'
```

The above alias, from within the context of an active Vagrant project, would
print the CPU and memory utilization directly to the console:

```
CPU: 4.20%, Memory: 11.00%
```
