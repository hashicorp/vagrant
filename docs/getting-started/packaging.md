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

Before working through the rest of this page, make sure the virtual environment
is built by running `vagrant up`.

## Creating the Vagrantfile

The first step is to create a Vagrantfile which does most of the heavy
lifting for the users of your box and to remove code which isn't useful
for boxes. First, backup your old Vagrantfile by copying it to something like
`Vagrantfile.bak`. Then, remove everything pertaining to provisioning, since the
packaged box will already be fully provisioned since its an export of the
running virtual machine. Second, remove the base box configuration, since
there is no base box for a box. And finally, we need to add in the MAC address of the
virtual machine so the internet access will work on any machine (more on
this later). The resulting Vagrantfile should look like the following:

{% highlight ruby %}
Vagrant::Config.run do |config|
  # Mac address (make sure this matches _exactly_)
  config.vm.base_mac = "0800279C2E41"

  # Forward apache
  config.vm.forward_port("web", 80, 8080)
end
{% endhighlight %}

## Packaging the Project

Run the following code to package the environment up:

{% highlight bash %}
$ vagrant halt
$ vagrant package --include Vagrantfile
{% endhighlight %}

The first command simply halts the running virtual machine (if its running).
This is basically equivalent to pulling the plug on our machine and is not
recommended in general. In this case, it shouldn't really cause any damage.

The second command is where the meat is. `vagrant package` takes the virtual
environment from the current project and packages it into a `package.box`
file in the same directory. The additional options passed to the command tell
it to include the newly created Vagrantfile with it, so that the users of
the box will already have the MAC address and port forwarding setup.

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
environment! Notice that they don't have to do provisioning or any of that;
since we already did all that, the exported virtual machine has it done
already.