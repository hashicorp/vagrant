---
page_title: "Boxes - Getting Started"
sidebar_current: "gettingstarted-boxes"
---

# Boxes

Instead of building a virtual machine from scratch, which would be a
slow and tedious process, Vagrant uses a base image to quickly clone
a virtual machine. These base images are known as _boxes_ in Vagrant,
and specifying the box to use for your Vagrant environment is always
the first step after creating a new Vagrantfile.

## Installing a Box

If you ran the commands on the [getting started overview page](/v2/getting-started/index.html),
then you've already installed a box before, and you don't need to run
the commands below again. However, it is still worth reading this section
to learn more about how boxes are managed.

Boxes are added to Vagrant with `vagrant box add`. This stores the box
under a specific name so that multiple Vagrant environments can re-use it.
If you haven't added a box yet, you can do so now:

```
$ vagrant box add precise32 \
    http://files.vagrantup.com/precise32.box
```

This will download the box from an HTTP source and save it as "precise32"
in a directory that Vagrant manages (away from your project). You can also
add boxes from a local file path.

Added boxes can be re-used by multiple projects. Each project uses a box
as an initial image to clone from, and never modifies the actual base
image. This means that if you have two projects both using the `precise32`
box we just added, adding files in one guest machine will have no effect
on the other machine.

## Using a Box

Now that the box has been added to Vagrant, we need to configure our
project to use it as a base. Open the `Vagrantfile` and change the
contents to the following:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "precise32"
end
```

The "precise32" in this case must match the name you used to add
the box above. This is how Vagrant knows what box to use.

In the next section, we'll bring up the guest machine and interact
with it a little bit.
