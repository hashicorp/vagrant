---
layout: getting_started
title: Getting Started - Introduction

current: Introduction
previous: Why Vagrant?
previous_url: /docs/getting-started/why.html
next: Project Setup
next_url: /docs/getting-started/setup.html
---
# Introduction

This initial section will introduce the binaries and Vagrantfile, which are
used extensively in controlling Vagrant. The remainder of the getting started
guides assumes this basic knowledge.

## Vagrant Binary

Once Vagrant is installed, it is typically controlled through the `vagrant`
command line interface. The `vagrant` binary has many "subcommands" which can be
invoked which handle all the functionality within Vagrant, such as `vagrant up`,
`vagrant ssh`, and `vagrant package`, to name a few. To discover all the supported
subcommands, just run `vagrant` alone, and it'll list them out for you.

## The Vagrantfile

A `Vagrantfile` is to Vagrant as a `Makefile` is to Make. The `Vagrantfile` exists at the root
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
