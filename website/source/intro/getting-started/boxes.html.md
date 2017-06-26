---
layout: "intro"
page_title: "Boxes - Getting Started"
sidebar_current: "gettingstarted-boxes"
description: |-
  Instead of building a virtual machine from scratch, which would be a
  slow and tedious process, Vagrant uses a base image to quickly clone
  a virtual machine. These base images are known as "boxes" in Vagrant,
  and specifying the box to use for your Vagrant environment is always
  the first step after creating a new Vagrantfile.
---

# Boxes

Instead of building a virtual machine from scratch, which would be a
slow and tedious process, Vagrant uses a base image to quickly clone
a virtual machine. These base images are known as "boxes" in Vagrant,
and specifying the box to use for your Vagrant environment is always
the first step after creating a new Vagrantfile.

## Installing a Box

If you ran the commands on the [getting started overview page](/intro/getting-started/),
then you've already installed a box before, and you do not need to run
the commands below again. However, it is still worth reading this section
to learn more about how boxes are managed.

Boxes are added to Vagrant with `vagrant box add`. This stores the box
under a specific name so that multiple Vagrant environments can re-use it.
If you have not added a box yet, you can do so now:

```
$ vagrant box add hashicorp/precise64
```

This will download the box named "hashicorp/precise64" from
[HashiCorp's Vagrant Cloud box catalog](https://vagrantcloud.com/boxes/search), a place where you can find
and host boxes. While it is easiest to download boxes from HashiCorp's Vagrant Cloud
you can also add boxes from a local file, custom URL, etc.

Boxes are globally stored for the current user. Each project uses a box
as an initial image to clone from, and never modifies the actual base
image. This means that if you have two projects both using the `hashicorp/precise64`
box we just added, adding files in one guest machine will have no effect
on the other machine.

In the above command, you will notice that boxes are namespaced. Boxes are
broken down into two parts - the username and the box name - separated by a
slash. In the example above, the username is "hashicorp", and the box is
"precise64". You can also specify boxes via URLs or local file paths, but that
will not be covered in the getting started guide.

~> **Namespaces do not guarantee canonical boxes!** A common misconception is
that a namespace like "ubuntu" represents the canonical space for Ubuntu boxes.
This is untrue. Namespaces on Vagrant Cloud behave very similarly to namespaces on
GitHub, for example. Just as GitHub's support team is unable to assist with
issues in someone's repository, HashiCorp's support team is unable to assist
with third-party published boxes.

## Using a Box

Now that the box has been added to Vagrant, we need to configure our
project to use it as a base. Open the `Vagrantfile` and change the
contents to the following:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/precise64"
end
```

The "hashicorp/precise64" in this case must match the name you used to add
the box above. This is how Vagrant knows what box to use. If the box was not
added before, Vagrant will automatically download and add the box when it is
run.

You may specify an explicit version of a box by specifying `config.vm.box_version`
for example:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/precise64"
  config.vm.box_version = "1.1.0"
end
```

You may also specify the URL to a box directly using `config.vm.box_url`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"
end
```

In the next section, we will bring up the Vagrant environment and interact
with it a little bit.

## Finding More Boxes

For the remainder of this getting started guide, we will only use the
"hashicorp/precise64" box we added previously. But soon after finishing
this getting started guide, the first question you will probably have is
"where do I find more boxes?"

The best place to find more boxes is [HashiCorp's Vagrant Cloud box catalog](https://vagrantcloud.com/boxes/search).
HashiCorp's Vagrant Cloud has a public directory of freely available boxes that
run various platforms and technologies. HashiCorp's Vagrant Cloud also has a great search
feature to allow you to find the box you care about.

In addition to finding free boxes, HashiCorp's Vagrant Cloud lets you host your own
boxes, as well as private boxes if you intend on creating boxes for your
own organization.

## Next Steps

You have successfully downloaded your first Vagrant box and configured the
Vagrantfile to utilize that box. Read on to learn about [bringing up and access
the Vagrant machine via SSH](/intro/getting-started/up.html).
