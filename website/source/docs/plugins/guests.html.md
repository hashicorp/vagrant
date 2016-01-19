---
layout: "docs"
page_title: "Custom Guests - Plugin Development"
sidebar_current: "plugins-guests"
description: |-
  This page documents how to add new guest OS detection to Vagrant, allowing
  Vagrant to properly configure new operating systems. Prior to reading this,
  you should be familiar with the plugin development basics.
---

# Plugin Development: Guests

This page documents how to add new guest OS detection to Vagrant, allowing
Vagrant to properly configure new operating systems.
Prior to reading this, you should be familiar
with the [plugin development basics](/docs/plugins/development-basics.html).

<div class="alert alert-warning">
  <strong>Warning: Advanced Topic!</strong> Developing plugins is an
  advanced topic that only experienced Vagrant users who are reasonably
  comfortable with Ruby should approach.
</div>

Vagrant has many features that requires doing guest OS-specific
actions, such as mounting folders, configuring networks, etc. These
tasks vary from operating system to operating system. If you find that
one of these does not work for your operating system, then maybe the
guest implementation is incomplete or incorrect.

## Definition Component

Within the context of a plugin definition, new guests can be defined
like so:

```ruby
guest "ubuntu" do
  require_relative "guest"
  Guest
end
```

Guests are defined with the `guest` method. The first argument is the
name of the guest. This name is not actually used anywhere, but may in the
future, so choose something helpful. Then, the block argument returns a
class that implements the `Vagrant.plugin(2, :guest)` interface.

## Implementation

Implementations of guests subclass `Vagrant.plugin("2", "guest")`. Within
this implementation, only the `detect?` method needs to be implemented.

The `detect?` method is called by Vagrant at some point after the machine
is booted in order to determine what operating system the guest is running.
If you detect that it is your operating system, return `true` from `detect?`.
Otherwise, return `false`.

Communication channels to the machine are guaranteed to be running at this
point, so the most common way to detect the operating system is to do
some basic testing:

```
class MyGuest < Vagrant.plugin("2", "guest")
  def detect?(machine)
    machine.communicate.test("cat /etc/myos-release")
  end
end
```

After detecting an OS, that OS is used for various
[guest capabilities](/docs/plugins/guest-capabilities.html) that may be
required.

## Guest Inheritance

Vagrant also supports a form of inheritance for guests, since sometimes
operating systems stem from a common root. A good example of this is Linux
is the root of Debian, which further is the root of Ubuntu in many cases.
Inheritance allows guests to share a lot of common behavior while allowing
distro-specific overrides.

Inheritance is not done via standard Ruby class inheritance because Vagrant
uses a custom [capability-based](/docs/plugins/guest-capabilities.html) system.
Vagrant handles inheritance dispatch for you.

To subclass another guest, specify that guest's name as a second parameter
in the guest definition:

```ruby
guest "ubuntu", "debian" do
  require_relative "guest"
  Guest
end
```

With the above component, the "ubuntu" guest inherits from "debian." When
a capability is looked up for "ubuntu", all capabilities from "debian" are
also available, and any capabilities in "ubuntu" override parent capabilities.

When detecting operating systems with `detect?`, Vagrant always does a
depth-first search by searching the children operating systems before
checking their parents. Therefore, it is guaranteed in the above example
that the `detect?` method on "ubuntu" will be called before "debian."
