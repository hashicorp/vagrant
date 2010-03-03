---
layout: getting_started
title: Getting Started - Packaging
---
# Packaging

With the virtual machine working and ready, we're ready to get to work.
But let's assume in this situation that you have other team members, and
you want to share the same virtual environment with them. Let's package this
new environment into a box for them so they can get up and running
with just a few keystrokes.

Packages are tar files ending in the suffix 'box' (hence known as box files)
containing the exported virtual machine and optionally
additional files specified on the command line. A common file also included
with boxes is a Vagrantfile. If a Vagrantfile exists in a box, it will be
added to the configuration load chain. Boxes can use a Vagrantfile to specify
default forwarded ports, SSH information, etc.

## Packaging the Project

Run the following code to package the environment up. This code requires
that the environment already exist, so before packaging run `vagrant up`.

{% highlight bash %}
$ vagrant halt
$ vagrant package
{% endhighlight %}

The first command simply halts the running virtual machine (if its running).
This is basically equivalent to pulling the plug on our machine and is not
recommended in general. In this case, it shouldn't really cause any damage.

The second command is where the meat is. `vagrant package` takes the virtual
environment from the current project and packages it into a `package.box`
file in the same directory.

## Distributing the Box

Vagrant currently supports installing boxes from local file path or from
HTTP. If the box you're distributing has private data on it (such as a
company's web application or client work for freelancers), then you should
keep the box on a secure filesystem where the public cannot access it.

If the box you're distributing is meant to be public, HTTP is the best
resource to upload to, so that anyone can easily download it.

Once the box is in place, other developers can add it like any other box:

{% highlight bash %}
$ vagrant box add my_box /path/to/the/package.box
{% endhighlight %}

After that they just have to configure their Vagrantfile to use the box as
a base, run `vagrant up`, and they should have a fully working development
environment!