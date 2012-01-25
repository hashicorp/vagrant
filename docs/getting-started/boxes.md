---
layout: getting_started
title: Getting Started - Boxes

current: Boxes
previous: Project Setup
previous_url: /docs/getting-started/setup.html
next: SSH
next_url: /docs/getting-started/ssh.html
---
# Boxes

After project initialization, the first step is always to specify the
_base box_ in the Vagrantfile. Vagrant doesn't create a virtual machine
instance _completely_ from scratch. Instead, it imports a base image for
a VM and builds off of that. This simplifes things greatly for Vagrant
users since they don't have to spend time specifying tedious details
such as memory capacity, hard disk capacity, network controllers, etc,
and also allows customizable bases to build projects from.

The bases that Vagrant builds off are packaged as "boxes," which are
basically tar packages in a specific format for Vagrant use. Anybody
can create a box, and packaging will be covered specifically in the
[packaging](/docs/getting-started/packaging.html) section.

## Getting a Base Box

We've already packaged a base box which has a bare bones installation
of Ubuntu Lucid (10.04) 32-bit. Note that if you already downloaded
this box from the [overview page](/docs/getting-started/index.html) you
do not have to download it again.

Vagrant supports adding boxes from both the local filesystem and an
HTTP URL. Begin running the following command so it can begin downloading
while box installation is covered in more detail:

{% highlight bash %}
$ vagrant box add lucid32 http://files.vagrantup.com/lucid32.box
{% endhighlight %}

Installed boxes are global to the current vagrant installation. This
means that once the `lucid32` box has been added, it can be used by
multiple projects at the same time. Each project uses the box as a _base_ only, so once the
project VM is created, modifications can be made without affecting other
projects which may use the same box.

Note that the box is given its own name, in this case "lucid32." This name
is used throughout Vagrant to reference that box from this point forward.
The URL is only used when adding, but never again. And the filename of the
box means nothing to the logical name given. It is simply a coincidence that
the filename and logical name are equal in this case.

## Removing Boxes

Just as easily as they're added, boxes can be removed as well (but note that
deletion is permanent). The following is an example command to remove a box.

{% highlight bash %}
$ vagrant box remove my_box
{% endhighlight %}

If you tried to run this command, it will obviously fail, since you haven't
added a box named "my_box" yet (or if you have, I'm sorry because you just
deleted it forever).

Once a box is removed, no new virtual machines based on that box can be created,
since it is completely deleted off the filesystem, but existing virtual machines
which have already been spun up will continue to function properly.

## Configuring the Project to use the Box

Now that the lucid box has been successfully added to the Vagrant installation,
we need to tell our project to use it as a base. This is done through the Vagrantfile.
Open the Vagrantfile and paste the following contents into it. The functional of
the contents should be self-explanatory:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.box = "lucid32"
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
`vagrant destroy`.

{% highlight bash %}
$ vagrant up
...
$ vagrant destroy
...
{% endhighlight %}
