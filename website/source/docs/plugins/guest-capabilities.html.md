---
layout: "docs"
page_title: "Guest Capabilities - Plugin Development"
sidebar_current: "plugins-guestcapabilities"
description: |-
  This page documents how to add new capabilities for guests to Vagrant,
  allowing Vagrant to perform new actions on specific guest operating systems.
  Prior to reading this, you should be familiar with the plugin development
  basics.
---

# Plugin Development: Guest Capabilities

This page documents how to add new capabilities for [guests](/docs/plugins/guests.html)
to Vagrant, allowing Vagrant to perform new actions on specific guest
operating systems.
Prior to reading this, you should be familiar
with the [plugin development basics](/docs/plugins/development-basics.html).

<div class="alert alert-warning">
  <strong>Warning: Advanced Topic!</strong> Developing plugins is an
  advanced topic that only experienced Vagrant users who are reasonably
  comfortable with Ruby should approach.
</div>

Guest capabilities augment [guests](/docs/plugins/guests.html) by attaching
specific "capabilities" to the guest, which are actions that can be performed
in the context of that guest operating system.

The power of capabilities is that plugins can add new capabilities to
existing guest operating systems without modifying the core of Vagrant.
In earlier versions of Vagrant, all the guest logic was contained in the
core of Vagrant and was not easily augmented.

## Definition Component

Within the context of a plugin definition, guest capabilities can be
defined like so:

```ruby
guest_capability "ubuntu", "my_custom_capability" do
  require_relative "cap/my_custom_capability"
  Cap::MyCustomCapability
end
```

Guest capabilities are defined by calling the `guest_capability` method,
which takes two parameters: the guest to add the capability to, and the
name of the capability itself. Then, the block argument returns a class
that implements a method named the same as the capability. This is
covered in more detail in the next section.

## Implementation

Implementations should be classes or modules that have a method with
the same name as the capability. The method must be immediately accessible
on the class returned from the `guest_capability` component, meaning that
if it is an instance method, an instance should be returned.

In general, class methods are used for capabilities. For example, here
is the implementation for the capability above:

```ruby
module Cap
  class MyCustomCapability
    def self.my_custom_capability(machine)
      # implementation
    end
  end
end
```

All capabilities get the Vagrant machine object as the first argument.
Additional arguments are determined by the specific capability, so view the
documentation or usage of the capability you are trying to implement for more
information.

Some capabilities must also return values back to the caller, so be aware
of that when implementing a capability.

Capabilities always have access to communication channels such as SSH
on the machine, and the machine can generally be assumed to be booted.

## Calling Capabilities

Since you have access to the machine in every capability, capabilities can
also call _other_ capabilities. This is useful for using the inheritance
mechanism of capabilities to potentially ask helpers for more information.
For example, the "redhat" guest has a "network\_scripts\_dir" capability that
simply returns the directory where networking scripts go.

Capabilities on child guests of RedHat such as CentOS or Fedora use this
capability to determine where networking scripts go, while sometimes overriding
it themselves.

Capabilities can be called like so:

```ruby
machine.guest.capability(:capability_name)
```

Any additional arguments given to the method will be passed on to the
capability, and the capability will return the value that the actual
capability returned.
