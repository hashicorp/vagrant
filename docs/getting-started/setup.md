---
layout: getting_started
title: Getting Started - Project Setup
---
# Project Setup

The remainder of this getting started guide is written as a walkthrough.
As the reader, you are encouraged to follow along with the samples on your own
personal computer. Since Vagrant works with virtual machines, there will be no
"cruft" left over if you ever wish to stop (no extraneous software, files, etc)
as Vagrant will handle destroying the virtual machine if you so choose.

## Vagrant Project Setup

The first step for any project which uses Vagrant is to mark the root directory
and setup the basic required files. Vagrant provides a handy command-line utility
for just that. In the terminal transcript below, we create the directory for our
project and initialize it for Vagrant:

{% highlight bash %}
$ mkdir vagrant_guide
$ cd vagrant_guide
$ vagrant init
{% endhighlight %}

`vagrant init` creates an initial Vagrantfile. For now, we'll leave this Vagrantfile
as-is, but it will be used extensively in future steps to configure our virtual
machine.

## Rails Project Setup

With Vagrant now ready for the given directory, lets add rails to it. In the
same directory run the `rails` command:

{% highlight bash %}
$ rails .
{% endhighlight %}

This creates a rails-app in the current directory. We'll leave it as-is.

The above setups required (rails and vagrant) could have been run in any order.
Vagrant can easily be initialized in already-existing project folders.