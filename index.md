---
layout: welcome
title: Welcome
---
Vagrant is a tool for building and distributing virtualized development environments.

By providing automated creation and provisioning of virtual machines
using [Oracle's VirtualBox](http://www.virtualbox.org), Vagrant provides
the tools to create and configure lightweight, reproducible, and portable
virtual environments. For more information, see the part of the
getting started guide on "[Why Vagrant?](/docs/getting-started/why.html)"

Are you ready to revolutionize the way you work? Check out
the [getting started guide](/docs/getting-started/index.html), the
[getting started video](http://vimeo.com/9976342).

## Your First Vagrant Virtual Environment

{% highlight bash %}
$ gem install vagrant   # installs Vagrant on your system
$ vagrant box add base http://files.vagrantup.com/lucid32.box   # creates a "base box" named "base"
$ vagrant init    # creates a Vagrantfile, which allows you to configure your VM how you like it
$ vagrant up   # boot up the VM
{% endhighlight %}

These four commands alone will automatically download and create a bare bones
Ubuntu-based server running in the background. Sure, that on its own isn't
that amazing, but imagine running a single `vagrant up` and having a fully
featured web development environment running! This is all possible with Vagrant.

## Feature List

This is a compact feature list of Vagrant. For more information on any of
the specific features, read the [getting started guide](/docs/getting-started/index.html).

* Automated virtual machine creation using [Oracle's VirtualBox](http://www.virtualbox.org)
* Automated provisioning of virtual environments using [Chef](http://www.opscode.com/chef) or [Puppet](http://www.puppetlabs.com/puppet).
* Full SSH access to created environments
* Assign a static IP to your VM, accessible from your machine
* Forward ports to the host machine
* Shared folders allows you to continue using your own editor
* Package environments into distributable boxes
* Completely tear down environment when you're done
* Easily rebuild a complete environment with a single command
