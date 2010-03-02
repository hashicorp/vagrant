---
layout: default
title: Getting Started
---
This getting started guide will walk you through the basics of setting up and
building your first virtual machine with vagrant. The VM built from this page
will largely be useless from a development point of view, but functions to introduce
you to the basic concepts of Vagrant. This guide will not introduce the provisioning
functionality or packaging system built-in to vagrant.

After the getting started guide, we recommend you read the [Vagrant tutorial](/docs/tutorial/index.html),
which is a much more detailed guide which sets up an HTTP server with MySQL to
run in the background.

## Getting Started in Less than 5 Minutes

Let's get started with the bare minimum needed to get your first virtual environment
running, then we'll go over them step by step. After running the following sequence of
commands, you'll have a fully functional Ubuntu-based server running in the background!

{% highlight bash %}$ sudo gem install vagrant
$ vagrant box add base http://files.vagrantup.com/base.box
$ vagrant init
$ vagrant up{% endhighlight %}

## Step-by-Step Explanations

### Installation

Vagrant is packaged as a [RubyGem](http://rubygems.org/). Since Vagrant is written
in Ruby and RubyGems is a standard part of most Ruby installations, RubyGems is the
quickest and easiest way to distribute Vagrant to the masses, and it can be installed
just as easily:

{% highlight bash %}
$ sudo gem install vagrant
{% endhighlight %}

**Note:** Although Vagrant is written in Ruby and packaged as a RubyGem, Vagrant usage
is _not limited to Ruby-based projects only_. Vagrant will work happily with any project,
no matter what language its written in or uses.

### Add a Box

Vagrant doesn't build a virtual machine _completely_ from scratch. To save time, all VMs
are built from a base, which can be thought of as a preconfigured VM, but only a skeleton.
These base VM configurations are packaged in `box` files, and can be added using the
`vagrant box` command.

Boxes can be built by anyone, including you! But to help you get started, we host our own
bare bones box which is an Ubuntu-based server VM with 360 MB of RAM (by default) and 40 GB
of dynamically-resizing disk storage.

The following command downloads this box from our host and installs it for use:

{% highlight bash %}
$ vagrant box add base http://files.vagrantup.com/base.box
{% endhighlight %}

For more details on boxes such as their structure, where they are unpackaged to, etc.
please read the detailed technical documentation (coming soon).

### Initialize Your Project

Just like make uses a `Makefile` and rake uses a `Rakefile`, Vagrant uses a `Vagrantfile`!
This file is used to configure a project's virtual environment, such as what box to build off
of, what ports to forward, where to share folders, etc. This file is required prior to building
any Vagrant environment.

`vagrant init` simply copies a premade `Vagrantfile` to the current working directory which
by default has a single configuration option to build from the "base" box.

{% highlight bash %}
$ vagrant init
{% endhighlight %}

### Vagrant Up!

Finally, `vagrant up` brings everything together by building a personalized VM from all
the pieces. While in this simple example, Vagrant appears to simply be importing a
virtual machine and starting it, Vagrant is much more powerful than that! Through simple
configuration, Vagrant can forward ports, automatically provision systems with [chef](http://www.opscode.com/chef/),
share folders, and more.

{% highlight bash %}
$ vagrant up
{% endhighlight %}