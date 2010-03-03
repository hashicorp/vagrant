---
layout: getting_started
title: Getting Started - Introduction
---
# Introduction

This initial section will introduce the binaries and Vagrantfile, which are
used extensively in controlling Vagrant. The remainder of the getting started
guides assumes this basic knowledge.

## Vagrant Binaries

Once Vagrant is installed, it is typically controlled through the `vagrant`
command line interface. Vagrant comes with around 10 separate binaries, all prefixed
with `vagrant`, such as `vagrant-up`, `vagrant-ssh`, and `vagrant-package`. These are
known as _git style binaries_ (since they mimic git). Taking it one step further,
the hyphen between the commands are optional. To call `vagrant-up` for example, you
could just do `vagrant up` and the two commands would behave the exact same way.

## The Vagrantfile

A Vagrantfile is to Vagrant as a Makefile is to Make. The Vagrantfile exists at the root
of any Vagrant project and is used to configure and specify the behavior of
Vagrant and the virtual machine it creates. A basic Vagrantfile is embedded below
so you can get a brief idea of how it looks:

{% highlight ruby %}
Vagrant::Config.run do |config|
  # Setup the box
  config.vm.box = "my_box"
end
{% endhighlight %}

As you can see, a Vagrantfile is simply Ruby code which typically contains a Vagrant
configuration block. For most commands, Vagrant will first load the project's
Vagrantfile for configuration.