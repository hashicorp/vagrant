---
layout: getting_started
title: Getting Started

current: Overview
next: Why Vagrant?
next_url: /docs/getting-started/why.html
---
# Getting Started with Vagrant

Vagrant uses [Oracle's VirtualBox](http://www.virtualbox.org)
to build configurable, lightweight, and portable virtual machines dynamically.
The first couple pages serve to introduce you to Vagrant and what it has
to offer while the rest of the guide is a technical walkthrough for building a
fully functional web development environment. The getting started
guide concludes by explaining how to package the newly created vagrant environment
so other developers can get up and running in just a couple commands.

## Get VirtualBox

Vagrant depends on [Oracle's VirtualBox](http://www.virtualbox.org) to create all of
its virtual environments. VirtualBox is a general-purpose full virtualizer for
x86 hardware. Targeted at server, desktop and embedded use, it is a
professional-quality virtualization solution that is also open source software.
VirtualBox runs on **Windows**, **Mac OS X**, **Linux**, and **Solaris**.

Here is a link directly to the [download page](http://www.virtualbox.org/wiki/Downloads).

Vagrant currently supports VirtualBox 4.0.x and 4.1.x.

## Install Vagrant

To install Vagrant, download the appropriate package or installer from the
[downloads page](http://downloads.vagrantup.com), and install it using standard
operating system procedures. On Windows and Mac OS X, the `vagrant` command should
automatically be placed on your `PATH`. On other systems, you must add `/opt/vagrant/bin`
to your `PATH`.

If a Vagrant package is not available for your platform, you can also install
using [RubyGems](http://rubygems.org/gems/vagrant) via a `gem install vagrant`.
But note that the packages are the preferred and best supported method of installation.

## Your First Vagrant Virtual Environment

<pre>
$ vagrant box add lucid32 http://files.vagrantup.com/lucid32.box
$ vagrant init lucid32
$ vagrant up
</pre>

While the rest of the getting started guide will focus on explaining how to
build a fully functional virtual machine to serve Rails applications, you
should get used to the above snippet of code. After the initial setup of
any Vagrant environment, the above is all any developer will need to create
their development environment! Note that the above snippet does actually
create a fully functional 512MB virtual machine running Ubuntu in the
background, although the machine doesn't do much in this state.
