---
layout: documentation
title: Documentation - Boxes
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
The following adds a box named `lucid32` to a local vagrant
installation:

{% highlight bash %}
$ vagrant box add lucid32 http://files.vagrantup.com/lucid32.box
{% endhighlight %}

The name used with the `vagrant box add` command is the name used to
reference the box from that point forward. Any box can be named anything
you want.  Boxes that are added using `vagrant box add` are global to the
vagrant install, and they are stored at `~/.vagrant.d/boxes` on the local filesystem.

**Note:** The default Vagrantfile created with `vagrant init` defaults to
using a box named "base." This is why in the getting started guide, the
first few commands tell you to add a box named "base" to the project.

## Removing a Box

Boxes can just as easily be removed using the same `vagrant box` command.
The following command removes the `lucid32` box which was added in the
previous section:

{% highlight bash %}
$ vagrant box remove lucid32
{% endhighlight %}

**Warning:** There is no going back from this command. This command literally
deletes the files off the filesystem.

## Listing Installed Boxes

Keeping track of the installed boxes can be difficult. Vagrant provides the
`vagrant box list` command to list all installed boxes.

{% highlight bash %}
$ vagrant box list
lucid32
{% endhighlight %}

<a name="creating-a-box"> </a>
## Creating a Box

Boxes are created from a vagrant project. So the first step to creating a box
is to setup a project the way you want. Add provisioning, share folders,
etc. Anything you need to get your environment in the correct state. Once
there, just run `vagrant package` and it'll package the environment and
save it to `package.box` in the current working directory.

Note that `vagrant package` will not include the Vagrantfile or any files other
than the exported virtual machine. If you wish to include additional files or a
Vagrantfile, use the `--include` and/or `--vagrantfile` options, respecitvely.
An example below:

{% highlight bash %}
$ vagrant package --vagrantfile Vagrantfile.pkg --include README.txt
{% endhighlight %}
