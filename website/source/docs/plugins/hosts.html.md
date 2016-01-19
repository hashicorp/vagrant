---
layout: "docs"
page_title: "Custom Hosts - Plugin Development"
sidebar_current: "plugins-hosts"
description: |-
  This page documents how to add new host OS detection to Vagrant, allowing
  Vagrant to properly execute host-specific operations on new operating systems.
  Prior to reading this, you should be familiar with the plugin development
  basics.
---

# Plugin Development: Hosts

This page documents how to add new host OS detection to Vagrant, allowing
Vagrant to properly execute host-specific operations on new operating systems.
Prior to reading this, you should be familiar
with the [plugin development basics](/docs/plugins/development-basics.html).

<div class="alert alert-warning">
  <strong>Warning: Advanced Topic!</strong> Developing plugins is an
  advanced topic that only experienced Vagrant users who are reasonably
  comfortable with Ruby should approach.
</div>

Vagrant has some features that require host OS-specific actions, such as
exporting NFS folders. These tasks vary from operating system to operating
system. Vagrant uses host detection as well as
[host capabilities](/docs/plugins/host-capabilities.html) to perform these
host OS-specific operations.

## Definition Component

Within the context of a plugin definition, new hosts can be defined
like so:

```ruby
host "ubuntu" do
  require_relative "host"
  Host
end
```

Hosts are defined with the `host` method. The first argument is the
name of the host. This name is not actually used anywhere, but may in the
future, so choose something helpful. Then, the block argument returns a
class that implements the `Vagrant.plugin(2, :host)` interface.

## Implementation

Implementations of hosts subclass `Vagrant.plugin("2", "host")`. Within
this implementation, only the `detect?` method needs to be implemented.

The `detect?` method is called by Vagrant very early on in its initialization
process to determine if the OS that Vagrant is running on is this host.
If you detect that it is your operating system, return `true` from `detect?`.
Otherwise, return `false`.

```
class MyHost < Vagrant.plugin("2", "host")
  def detect?(environment)
    File.file?("/etc/arch-release")
  end
end
```

After detecting an OS, that OS is used for various
[host capabilities](/docs/plugins/host-capabilities.html) that may be
required.

## Host Inheritance

Vagrant also supports a form of inheritance for hosts, since sometimes
operating systems stem from a common root. A good example of this is Linux
is the root of Debian, which further is the root of Ubuntu in many cases.
Inheritance allows hosts to share a lot of common behavior while allowing
distro-specific overrides.

Inheritance is not done via standard Ruby class inheritance because Vagrant
uses a custom [capability-based](/docs/plugins/host-capabilities.html) system.
Vagrant handles inheritance dispatch for you.

To subclass another host, specify that host's name as a second parameter
in the host definition:

```ruby
host "ubuntu", "debian" do
  require_relative "host"
  Host
end
```

With the above component, the "ubuntu" host inherits from "debian." When
a capability is looked up for "ubuntu", all capabilities from "debian" are
also available, and any capabilities in "ubuntu" override parent capabilities.

When detecting operating systems with `detect?`, Vagrant always does a
depth-first search by searching the children operating systems before
checking their parents. Therefore, it is guaranteed in the above example
that the `detect?` method on "ubuntu" will be called before "debian."
