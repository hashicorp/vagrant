---
layout: documentation
title: Documentation - Guest-specific Behavior

current: Guests
---
# Guest-specific Behavior

There are certain functions that Vagrant exposes which require operating system
specific tasks such as shutting down gracefully, mounting folders, modifying network
interfaces, etc. Vagrant abstracts these necessary functions into "guest"
implementations.

There is an implementation for every major OS type such as generic Linux, Debian,
Ubuntu, FreeBSD, etc.

<div class="alert alert-block alert-notice">
  <h3>This topic is for advanced users</h3>
  <p>
    The following topic is for <em>advanced</em> users. The majority of Vagrant users
    will never have to know about this.
  </p>
</div>

## Tasks

The following is a list of tasks which are delegated to guest classes:

* **Halting** - Shutting down the machine gracefully
* **Mounting Shared Folders** - Creating, mounting, and setting up the permissions
  for shared folders.
* **Configuring Network Interfaces** - Configuring network interfaces via static
  configuration, DHCP, etc.

This list will surely grow as Vagrant grows. For now, to implement a custom operating
system implementation, only the above two features need to be implemented.

## Creating a New Guest Implementation

Creating a new guest implementer is quite simple: Inherit from `Vagrant::Guest::Base`
and implement the stubbed method on that class. Instead of going over each method here,
I'll point you to the [base source file](http://github.com/mitchellh/vagrant/blob/master/lib/vagrant/guest/base.rb)
which is thoroughly commented to explain each method. Its also recommended you view the
[linux guest](http://github.com/mitchellh/vagrant/blob/master/lib/vagrant/guest/linux.rb)
to get an idea of what an implementation looks like.

## Using a New Guest Implementation

The new guest implementation should be specified as the `config.vm.guest` configuration
value. By default, this is `:linux`. A symbol represents a built-in guest type. For
your custom types, you should set the value as the class name for your new implementation.
Below is a sample Vagrantfile which does just this:

{% highlight ruby %}
# An example guest:
require 'bsd_guest'

Vagrant::Config.run do |config|
  # Set the guest to the proper class name:
  config.vm.guest = BSDGuest
end
{% endhighlight %}

The configured Vagrant environment will then use the custom guest implementation.
