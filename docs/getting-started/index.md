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
fully functional Ruby on Rails development environment. The getting started
guide concludes by explaining how to package the newly created vagrant environment
so other developers can get up and running in just a couple commands.

## Get VirtualBox

Vagrant depends on [Oracle's VirtualBox](http://www.virtualbox.org) to create all of
it's virtual environments. VirtualBox is a general-purpose full virtualizer for
x86 hardware. Targeted at server, desktop and embedded use, it is now the only
professional-quality virtualization solution that is also Open Source Software.
VirtualBox runs on **Windows**, **Mac OS X**, **Linux**, and **Solaris**.

Here is a link directly to the [download page](http://www.virtualbox.org/wiki/Downloads).

Vagrant currently supports VirtualBox 4.0.x and 4.1.x.

## Setting up Ruby and RubyGems

Although Vagrant is written in Ruby, web developers from many different languages
come to use it (Python, Java, Clojure, etc.). Therefore, if you've never setup Ruby
or RubyGems before, please check out our basic guides, written for different
popular operating systems listed below:

* [Windows](/docs/getting-started/setup/windows.html)
* [Mac OS X](/docs/getting-started/setup/mac.html)
* [Ubuntu](/docs/getting-started/setup/ubuntu.html)

Is your OS not listed above? Feel free ask for help via our [support channels](/support.html).
Or if you figure it out on your own, let us know how and we'll gladly update the
website.

## Install Vagrant

Vagrant is packaged as a [RubyGem](http://rubygems.org/). Since Vagrant is written
in Ruby and RubyGems is a standard part of most Ruby installations, RubyGems is the
quickest and easiest way to distribute Vagrant to the masses, and it can be installed
just as easily:

<pre>
$ gem install vagrant
</pre>

## Your First Vagrant Virtual Environment

<pre>
$ vagrant box add lucid32 http://files.vagrantup.com/lucid32.box
$ vagrant init lucid32
$ vagrant up
</pre>

While the rest of the getting started guide will focus on explaining how to
build a fully functional virtual machine to serve rails applications, you
should get used to the above snippet of code. After the initial setup of
any Vagrant environment, the above is all any developer will need to create
their development environment! Note that the above snippet does actually
create a fully functional 512MB virtual machine running Ubuntu in the
background, although the machine doesn't do much in this state.

The first command will download a large file with a VirtualBox image and 
vagrant configuration information, and unpack it in a `~/.vagrant.d`
directory. This is a VM that is used as the basis for VirtualBox instances.
