---
page_title: "Boxes"
sidebar_current: "boxes"
---

# Boxes

Boxes are the package format for Vagrant environments. A box can be used by
anyone on any platform that Vagrant supports to bring up an identical
working environment.

The `vagrant box` utility provides all the functionality for managing
boxes. You can read the documentation on the [vagrant box](/v2/cli/box.html)
command for more information.

The easiest way to use a box is to add a box from the
[publicly available catalog of Vagrant boxes](#).
You can also add and share your own customized boxes on this website.

Boxes also support versioning so that members of your team using Vagrant
can update the underlying box easily, and the people who create boxes
can push fixes and communicate these fixes efficiently.

You can learn all about boxes by reading this page as well as the
sub-pages in the navigation to the left.

## Discovering Boxes

The easiest way to find boxes is to look on the
[public Vagrant box catalog](#)
for a box matching your use case. The catalog contains most major operating
systems as bases, as well as specialized boxes to get you up and running
quickly with LAMP stacks, Ruby, Python, etc.

The boxes on the public catalog work with many different
[providers](/v2/providers/index.html). Whether you're using Vagrant with
VirtualBox, VMware, AWS, etc. you should be able to find a box you need.

Adding a box from the catalog is very easy. Each box shows you instructions
with how to add it, but they all follow the same format:

```
$ vagrant box add USER/BOX
...
```

For example: `vagrant box add hashicorp/precise64`. You can also quickly
initialize a Vagrant environment with `vagrant init hashicorp/precise64`.
