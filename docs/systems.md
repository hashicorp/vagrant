---
layout: documentation
title: Documentation - Systems
---
# Systems

Systems are an abstraction within Vagrant which describe how various operating system specific
tasks are to be run. Systems abstract away tasks such as shutting down, mounting folders, etc.
since some operating systems handle this slightly different. This opens the door to supporting
more than unix-like systems.

<div class="info">
  <h3>This topic is for advanced users</h3>
  <p>
    The following topic is for <em>advanced</em> users. The majority of Vagrant users
    will never have to do this. Therefore, only continue if you want to support a non-linux
    based operating system.
  </p>
</div>

## System Tasks

The following is a list of tasks which are delegated to system classes:

* **Halting** - Shutting down the machine gracefully
* **Mounting Shared Folders** - Creating, mounting, and setting up the permissions
  for shared folders.
* **Enabling Host Only Networks** - Preparing and enabling host only networks on
  specified interfaces.

This list will surely grow as Vagrant grows. For now, to implement a custom operating
system implementation, only the above two features need to be implemented.

## Creating a New System Implementer

Creating a new system implementer is quite simple: Inherit from `Vagrant::Systems::Base`
and implement the stubbed method on that class. Instead of going over each method here,
I'll point you to the [base source file](http://github.com/mitchellh/vagrant/blob/master/lib/vagrant/systems/base.rb)
which is thoroughly commented to explain each method. Its also recommended you view the
[linux system](http://github.com/mitchellh/vagrant/blob/master/lib/vagrant/systems/linux.rb)
which is currently the only system shipped with Vagrant.

## Using a New System Implementer

The new system implementer should be specified as the `config.vm.system` configuration
value. By default, this is `:linux`. A symbol represents a built-in system type. For
your custom types, you should set the value as the class name for your new implementer.
Below is a sample Vagrantfile which does just this:

{% highlight ruby %}
# An example system:
require 'bsd_system'

Vagrant::Config.run do |config|
  # Set the system to the proper class name:
  config.vm.system = BSDSystem
end
{% endhighlight %}

The configured Vagrant environment will then use the custom system implementation.
