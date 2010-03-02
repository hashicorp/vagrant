---
layout: guide
title: User Guide - Boxes
---
# Boxes

A Vagrant "box" is the term used to describe a packaged Vagrant
environment. A box is a portable file which can be used by others
to quickly get a virtual environment up and running. A box must
contain the necessary files for the VirtualBox VM and may optionally
include a Vagrantfile.

Boxes are also required as a base for all vagrant projects. The
`vagrant box` utility provides all the power for managing boxes.
`vagrant package` is used to create a box from a vagrant project.

## Installing a Box

Boxes can be installed from the filesystem or via HTTP (note that
if you're interested, its quite easy to extend this to support more
protocols). No matter the source, the installation method is the same.
The following adds a box named `ubuntu_base` to a local vagrant
installation:

{% highlight bash %}
$ vagrant box add ubuntu_base http://files.vagrantup.com/base.box
{% endhighlight %}

The name used with the `vagrant box add` command is the name used to
reference the box from that point forward. Any box can be named anything
you want.

**Note:** The default Vagrantfile created with `vagrant init` defaults to
using a box named "base." This is why in the getting started guide, the
first few commands tell you to add a box named "base" to the project.

## Removing a Box

Boxes can just as easily be removed using the same `vagrant box` command.
The following command removes the `ubuntu_base` box which was added in the
previous section:

{% highlight bash %}
$ vagrant box remove ubuntu_base
{% endhighlight %}

**Warning:** There is no going back from this command. This command literally
deletes the files off the filesystem.

## Creating a Box

Boxes are created from a vagrant project. So the first step to creating a box
is to setup a project the way you want. Add provisioning, share folders,
etc. Anything you need to get your environment in the correct state. Once
there, just run `vagrant package` and it'll package the environment and
save it to `package.box` in the current working directory.

Note that `vagrant package` will not include the Vagrantfile or any files other
than the exported virtual machine. If you wish to include additional files,
use the `--include` option. An example below:

{% highlight bash %}
# We want to include a Vagrantfile into this box
$ vagrant package --include Vagrantfile
{% endhighlight %}
