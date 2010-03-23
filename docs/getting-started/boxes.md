---
layout: getting_started
title: Getting Started - Boxes
---
# Boxes

After project initialization, the next step is always to setup the
_base box_. Vagrant doesn't create a virtual machine _completely_ from
scratch. Instead, it imports a base VM, and builds off of that. This
simplifies things greatly for both the Vagrant developers and for the
Vagrant users, since they don't have to spend time specifying tedious
details such as memory size, hard disk size, network controllers, etc.

The bases that Vagrant builds off are packaged as "boxes," which are
basically tar packages in a specific format for Vagrant use. Anybody
can create a box, and packaging will be covered specifically in the
[packaging](/docs/getting-started/packaging.html) section.

## Getting the Getting Started Box

We've already packaged a basic box which contains Apache2, Passenger,
and SQLite. While provisioning will be covered in the getting started
guide, we didn't want to burden you with downloading all the cookbooks
for all the servers, so we'll instead cover a more simple case, although
the rails box was created completely with Vagrant provisioning.

Vagrant supports adding boxes from both the local filesystem and an
HTTP URL. Begin running the following command so it can begin downloading
while box installation is covered in more detail:

{% highlight bash %}
$ vagrant box add getting_started http://files.vagrantup.com/getting_started.box
{% endhighlight %}

Installed boxes reside in ~/.vagrant/boxes, and they are global to the current vagrant
installation. This means that once the rails box has been added, it can be used by
multiple projects at the same time. Each project uses the box as a _base_ only, so once the
project VM is created, modifications can be made without affecting other
projects which may use the same box.

Note that the box is given its own name, in this case "rails." This name
is used throughout Vagrant to reference that box from this point forward.
The URL is only used when adding, but never again. And the filename of the
box means nothing to the logical name given. It is simply a coincidence that
the filename and logical name are equal in this case.

## Removing Boxes

Just as easily as they're added, boxes can be removed as well. The following
is an example command to remove a box.

**Do not run this command if you're following the guide. It is just an example.**

{% highlight bash %}
$ vagrant box remove my_box
{% endhighlight %}

Once a box is removed, no new virtual machines based on that box can be created,
since it is completely deleted off the filesystem, but existing virtual machines
which have already been spun up will continue to function properly.

## Configuring the Project to use the Box

Now that the rails box has been successfully added to the Vagrant system, we need
to tell our project to use it as a base. This is done through the Vagrantfile.
Open the Vagrantfile and paste the following contents into it. The function of the
contents should be self-explanatory:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.box = "getting_started"
end
{% endhighlight %}

## Testing the Setup

So far, we've only specified a base. No ports have been forwarded, no custom provisioning
has been done, etc. We literally just have one line of configuration in our Vagrantfile.
But even so, we already have a fully functional virtual machine. You can see for yourself
by running `vagrant up` which will create the environment. After a few minutes, you should
have a fully running virtual machine. We haven't yet forwarded any ports and we haven't covered
SSH yet, so you'll just have to take our word that its working for now. Finally,
when you're finished verifying the virtual machine, you can destroy everything with a
`vagrant down`.

{% highlight bash %}
$ vagrant up
...
$ vagrant down
...
{% endhighlight %}
