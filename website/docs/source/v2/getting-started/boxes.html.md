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
$ vagrant box add hashicorp/precise32
```

This will download the box named "hashicorp/precise32" from
[HashiCorp's Atlas box catalog](https://atlas.hashicorp.com/boxes/search), a place where you can find
and host boxes. While it is easiest to download boxes from HashiCorp's Atlas
you can also add boxes from a local file, custom URL, etc.

Added boxes can be re-used by multiple projects. Each project uses a box
as an initial image to clone from, and never modifies the actual base
image. This means that if you have two projects both using the `hashicorp/precise32`
box we just added, adding files in one guest machine will have no effect
on the other machine.

## Using a Box

Now that the box has been added to Vagrant, we need to configure our
project to use it as a base. Open the `Vagrantfile` and change the
contents to the following:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/precise32"
end
```

The "hashicorp/precise32" in this case must match the name you used to add
the box above. This is how Vagrant knows what box to use. If the box wasn't
added before, Vagrant will automatically download and add the box when it is
run.

In the next section, we'll bring up the Vagrant environment and interact
with it a little bit.

## Finding More Boxes

For the remainder of this getting started guide, we'll only use the
"hashicorp/precise32" box we added previously. But soon after finishing
this getting started guide, the first question you'll probably have is
"where do I find more boxes?"

The best place to find more boxes is [HashiCorp's Atlas box catalog](https://atlas.hashicorp.com/boxes/search).
HashiCorp's Atlas has a public directory of freely available boxes that
run various platforms and technologies. HashiCorp's Atlas also has a great search
feature to allow you to find the box you care about.

In addition to finding free boxes, HashiCorp's Atlas lets you host your own
boxes, as well as private boxes if you intend on creating boxes for your
own organization.

<a href="/v2/getting-started/project_setup.html" class="button inline-button prev-button">Project Setup</a>
<a href="/v2/getting-started/up.html" class="button inline-button next-button">Up And SSH</a>
