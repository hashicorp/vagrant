---
layout: getting_started
title: Getting Started
---
# Getting Started with Vagrant

Vagrant uses [Sun's VirtualBox](http://www.virtualbox.org)
to build configurable, lightweight, and portable virtual machines dynamically.
The first couple pages serve to introduce you to Vagrant and what it has
to offer while the rest of the guide is a technical walkthrough for building a
fully functional Ruby on Rails development environment. The getting started
guide concludes by explaining how to package the newly created vagrant environment
so other developers can get up and running in just a couple commands.

## Get VirtualBox

Vagrant depends on [Sun's VirtualBox](http://www.virtualbox.org) to create all of
it's virtual environments. VirtualBox is a general-purpose full virtualizer for
x86 hardware. Targeted at server, desktop and embedded use, it is now the only
professional-quality virtualization solution that is also Open Source Software.
VirtualBox runs on **Windows**, **Mac OS X**, **Linux**, and **Solaris**.

Here is a link directly to the [download page](http://www.virtualbox.org/wiki/Downloads).

## Install Vagrant

Vagrant is packaged as a [RubyGem](http://rubygems.org/). Since Vagrant is written
in Ruby and RubyGems is a standard part of most Ruby installations, RubyGems is the
quickest and easiest way to distribute Vagrant to the masses, and it can be installed
just as easily:

{% highlight bash %}
$ sudo gem install vagrant
{% endhighlight %}

## Your First Vagrant Virtual Environment

{% highlight bash %}
$ vagrant box add base http://files.vagrantup.com/base.box
$ vagrant init
$ vagrant up
{% endhighlight %}

While the rest of the getting started guide will focus on explaining how to
build a fully functional virtual machine to serve rails applications, you
should get used to the above snippet of code. After the initial setup of
any Vagrant environment, the above is all any developer will need to create
their development environment! Note that the above snippet does actually
create a fully functional 360MB virtual machine running Ubuntu in the
background, although the machine doesn't do much in this state.