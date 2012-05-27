---
layout: documentation
title: Documentation - Boxes

current: Boxes
---
# Boxes

A "box" is the base image used to create a virtual environment with
Vagrant. It is meant to be a portable file which can be used by
others on any platform that Vagrant runs in order to bring up a
running virtual environment. The `vagrant box` utility provides
all the power for managing boxes, and `vagrant package` is used
to create boxes.

Boxes provide only the base image for Vagrant. The moment you run
`vagrant up`, the box is copied so that it can be modified for that
virtual machine. Therefore, it is safe to remove or update the box
after a virtual machine has been created.

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
However, the name of the box is not significant in any way other than to
logically identify the box in a Vagrantfile or from the command line.

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
Vagrantfile, use the `--include` and/or `--vagrantfile` options, respectively.
An example below:

{% highlight bash %}
$ vagrant package --vagrantfile Vagrantfile.pkg --include README.txt
{% endhighlight %}
