---
layout: default
title: Getting Started
---
This getting started guide will walk you through the basics of setting up and
building your first virtual machine with vagrant. However, it will not introduce
the provisioning or packaging system built-in to vagrant. This guide will be
most helpful to those who have never used vagrant before and are just wanted to
get a brief feel for it before diving in head first into the deep end.

## Getting Started

### Installation

Vagrant is packaged as a [RubyGem](http://rubyforge.org/projects/rubygems). Note that
vagrant is _not limited to just ruby-based projects_. On the contrary, vagrant does not
care what tools or language your project uses, but the vagrant tool itself is written
in Ruby and can be installed simply:

{% highlight bash %}
$ gem install vagrant
{% endhighlight %}

### Initialize Your Project

Once you've got vagrant installed, you'll want to initialize it for your project or
projects. To do this, go to the root directory of your project, and do the following:

{% highlight bash %}
$ vagrant init
{% endhighlight %}

This will create an initial `Vagrantfile` in that directory, which is used not only
to mark the root directory of your project but also to control every aspect of vagrant.

### Build Your First Virtualized Environment!

Now that vagrant is setup for your project, you can simply build your first virtual
machine:

{% highlight bash %}
$ vagrant up
{% endhighlight %}

