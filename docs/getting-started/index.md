---
layout: getting_started
title: Getting Started
---
# Getting Started with Vagrant

Web developers use virtual environments every day with their web applications. From EC2 and Rackspace Cloud to specialized
solutions such as EngineYard and Heroku, virtualization is the tool of choice for easy deployment and infrastructure management.
Vagrant aims to take those very same principals and put them to work in the heart of the application lifecycle.
By providing easy to configure, lightweight, reproducible, and portable virtual machines targeted at
development environments, Vagrant helps maximize your productivity and flexibility.

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
their development environment!