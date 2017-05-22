---
layout: "docs"
page_title: "Boxes"
sidebar_current: "boxes"
description: |-
  Boxes are the package format for Vagrant environments. A box can be used by
  anyone on any platform that Vagrant supports to bring up an identical
  working environment.
---

# Boxes

Boxes are the package format for Vagrant environments. A box can be used by
anyone on any platform that Vagrant supports to bring up an identical
working environment.

The `vagrant box` utility provides all the functionality for managing
boxes. You can read the documentation on the [vagrant box](/docs/cli/box.html)
command for more information.

The easiest way to use a box is to add a box from the
[publicly available catalog of Vagrant boxes](https://vagrantcloud.com/boxes/search).
You can also add and share your own customized boxes on this website.

Boxes also support versioning so that members of your team using Vagrant
can update the underlying box easily, and the people who create boxes
can push fixes and communicate these fixes efficiently.

You can learn all about boxes by reading this page as well as the
sub-pages in the navigation to the left.

## Discovering Boxes

The easiest way to find boxes is to look on the
[public Vagrant box catalog](https://vagrantcloud.com/boxes/search)
for a box matching your use case. The catalog contains most major operating
systems as bases, as well as specialized boxes to get you up and running
quickly with LAMP stacks, Ruby, Python, etc.

The boxes on the public catalog work with many different
[providers](/docs/providers/). Whether you are using Vagrant with
VirtualBox, VMware, AWS, etc. you should be able to find a box you need.

Adding a box from the catalog is very easy. Each box shows you instructions
with how to add it, but they all follow the same format:

```
$ vagrant box add USER/BOX
```

For example: `vagrant box add hashicorp/precise64`. You can also quickly
initialize a Vagrant environment with `vagrant init hashicorp/precise64`.

~> **Namespaces do not guarantee canonical boxes!** A common misconception is
that a namespace like "ubuntu" represents the canonical space for Ubuntu boxes.
This is untrue. Namespaces on Vagrant Cloud behave very similarly to namespaces on
GitHub, for example. Just as GitHub's support team is unable to assist with
issues in someone's repository, HashiCorp's support team is unable to assist
with third-party published boxes.

## Official Boxes

HashiCorp (the makers of Vagrant) publish a basic Ubuntu 12.04 (32 and 64-bit) box that is available for minimal use cases. It is highly optimized, small in size, and includes support for Virtualbox and VMware. You can use it like this:

```shell
$ vagrant init hashicorp/precise64
```

or you can update your `Vagrantfile` as follows:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/precise64"
end
```

For other users, we recommend the [Bento boxes](https://vagrantcloud.com/bento). The Bento boxes are [open source](https://github.com/chef/bento) and built for a number of providers including VMware, Virtualbox, and Parallels. There are a variety of operating systems and versions available.

These are the only two officially-recommended box sets.

~> **It is often a point of confusion**, but Canonical (the company that makes the Ubuntu operating system) publishes boxes under the "ubuntu" namespace on Vagrant Cloud. These boxes only support Virtualbox and do not provide an ideal experience for most users. If you encounter issues with these boxes, please try the Bento boxes instead.
