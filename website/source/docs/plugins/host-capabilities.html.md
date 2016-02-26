---
layout: "docs"
page_title: "Host Capabilities - Plugin Development"
sidebar_current: "plugins-hostcapabilities"
description: |-
  This page documents how to add new capabilities for hosts to Vagrant, allowing Vagrant to perform new actions on specific host operating systems. Prior to reading this, you should be familiar with the plugin development basics.
---

# Plugin Development: Host Capabilities

This page documents how to add new capabilities for [hosts](/docs/plugins/hosts.html)
to Vagrant, allowing Vagrant to perform new actions on specific host
operating systems.
Prior to reading this, you should be familiar
with the [plugin development basics](/docs/plugins/development-basics.html).

<div class="alert alert-warning">
  <strong>Warning: Advanced Topic!</strong> Developing plugins is an
  advanced topic that only experienced Vagrant users who are reasonably
  comfortable with Ruby should approach.
</div>

Host capabilities augment [hosts](/docs/plugins/hosts.html) by attaching
specific "capabilities" to the host, which are actions that can be performed
in the context of that host operating system.

The power of capabilities is that plugins can add new capabilities to
existing host operating systems without modifying the core of Vagrant.
In earlier versions of Vagrant, all the host logic was contained in the
core of Vagrant and was not easily augmented.

## Definition and Implementation

The definition and implementation of host capabilities is identical
to [guest capabilities](/docs/plugins/guest-capabilities.html).

The main difference from guest capabilities, however, is that instead of
taking a machine as the first argument, all host capabilities take an
instance of `Vagrant::Environment` as their first argument.

Access to the environment allows host capabilities to access global state,
specific machines, and also allows them to call other host capabilities.

## Calling Capabilities

Since you have access to the environment in every capability, capabilities can
also call _other_ host capabilities. This is useful for using the inheritance
mechanism of capabilities to potentially ask helpers for more information.
For example, the "linux" guest has a "nfs\_check\_command" capability that
returns the command to use to check if NFS is running.

Capabilities on child guests of Linux such as RedHat or Arch use this
capability to mostly inherit the Linux behavior, except for this minor
detail.

Capabilities can be called like so:

```ruby
environment.host.capability(:capability_name)
```

Any additional arguments given to the method will be passed on to the
capability, and the capability will return the value that the actual
capability returned.
