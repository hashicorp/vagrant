---
layout: "docs"
page_title: "Command Plugins - Plugin Development"
sidebar_current: "plugins-commands"
description: |-
  This page documents how to add new commands to Vagrant, invokable
  via "vagrant YOUR-COMMAND". Prior to reading this, you should be familiar
  with the plugin development basics.
---

# Plugin Development: Commands

This page documents how to add new commands to Vagrant, invokable
via `vagrant YOUR-COMMAND`. Prior to reading this, you should be familiar
with the [plugin development basics](/docs/plugins/development-basics.html).

<div class="alert alert-warning">
  <strong>Warning: Advanced Topic!</strong> Developing plugins is an
  advanced topic that only experienced Vagrant users who are reasonably
  comfortable with Ruby should approach.
</div>

## Definition Component

Within the context of a plugin definition, new commands can be defined
like so:

```ruby
command "foo" do
  require_relative "command"
  Command
end
```

Commands are defined with the `command` method, which takes as an argument
the name of the command, in this case "foo." This means the command will be
invokable via `vagrant foo`. Then the block argument returns a class that
implements the `Vagrant.plugin(2, "command")` interface.

You can also define _non-primary commands_. These commands do not show
up in the `vagrant -h` output. They only show up if the user explicitly
does a `vagrant list-commands` which shows the full listing of available
commands. This is useful for highly specific commands or plugins that a
beginner to Vagrant would not be using anyways. Vagrant itself uses non-primary
commands to expose some internal functions, as well.

To define a non-primary command:

```ruby
command("foo", primary: false) do
  require_relative "command"
  Command
end
```

## Implementation

Implementations of commands should subclass `Vagrant.plugin(2, :command)`,
which is a Vagrant method that will return the proper superclass for
a version 2 command. The implementation itself is quite simple, since the
class needs to only implement a single method: `execute`. Example:

```ruby
class Command < Vagrant.plugin(2, :command)
  def execute
    puts "Hello!"
    0
  end
end
```

The `execute` method is called when the command is invoked, and it should
return the exit status (0 for success, anything else for error).

This is a command at its simplest form. Of course, the command superclass
gives you access to the Vagrant environment and provides some helpers to
do common tasks such as command line parsing.

## Parsing Command-Line Options

The `parse_options` method is available which will parse the command line
for you. It takes an [OptionParser](http://ruby-doc.org/stdlib-1.9.3/libdoc/optparse/rdoc/OptionParser.html)
as an argument, and adds some common elements to it such as the `--help` flag,
automatically showing help if requested. View the API docs directly for more
information.

This is recommended over raw parsing/manipulation of command line flags.
The following is an example of parsing command line flags pulled directly
from the built-in Vagrant `destroy` command:

```ruby
options = {}
options[:force] = false

opts = OptionParser.new do |o|
  o.banner = "Usage: vagrant destroy [vm-name]"
  o.separator ""

  o.on("-f", "--force", "Destroy without confirmation.") do |f|
    options[:force] = f
  end
end

# Parse the options
argv = parse_options(opts)
```

## Using Vagrant Machines

The `with_target_vms` method is a helper that helps you interact with
the machines that Vagrant manages in a standard Vagrant way. This method
automatically does the right thing in the case of multi-machine environments,
handling target machines on the command line (`vagrant foo my-vm`), etc.
If you need to do any manipulation of a Vagrant machine, including SSH
access, this helper should be used.

An example of using the helper, again pulled directly from the built-in
`destroy` command:

```ruby
with_target_vms(argv, reverse: true) do |machine|
  machine.action(:destroy)
end
```

In this case, it asks for the machines in reverse order and calls the
destroy action on each of them. If a user says `vagrant destroy foo`, then
the helper automatically only yields the `foo` machine. If no parameter
is given and it is a multi-machine environment, every machine in the environment
is yielded, and so on. It just does the right thing.

## Using the Raw Vagrant Environment

The raw loaded `Vagrant::Environment` object is available with the
'@env' instance variable.
