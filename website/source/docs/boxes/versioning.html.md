---
layout: "docs"
page_title: "Box Versioning"
sidebar_current: "boxes-versioning"
description: |-
  Since Vagrant 1.5, boxes support versioning. This allows the people who
  make boxes to push updates to the box, and the people who use the box
  have a simple workflow for checking for updates, updating their boxes,
  and seeing what has changed.
---

# Box Versioning

Since Vagrant 1.5, boxes support versioning. This allows the people who
make boxes to push updates to the box, and the people who use the box
have a simple workflow for checking for updates, updating their boxes,
and seeing what has changed.

If you are just getting started with Vagrant, box versioning is not too
important, and we recommend learning about some other topics first. But
if you are using Vagrant on a team or plan on creating your own boxes,
versioning is very important. Luckily, having versioning built right in
to Vagrant makes it easy to use and fit nicely into the Vagrant workflow.

This page will cover how to use versioned boxes. It does _not_ cover how
to update your own custom boxes with versions. That is covered in
[creating a base box](/docs/boxes/base.html).

## Viewing Versions and Updating

`vagrant box list` only shows _installed_ versions of boxes. If you want
to see all available versions of a box, you will have to find the box
on [HashiCorp's Vagrant Cloud](/docs/vagrant-cloud). An easy way to find a box
is to use the url `https://vagrantcloud.com/$USER/$BOX`. For example, for
the `hashicorp/precise64` box, you can find information about it at
`https://vagrantcloud.com/hashicorp/precise64`.

You can check if the box you are using is outdated with `vagrant box outdated`.
This can check if the box in your current Vagrant environment is outdated
as well as any other box installed on the system.

Finally, you can update boxes with `vagrant box update`. This will download
and install the new box. This _will not_ magically update running Vagrant
environments. If a Vagrant environment is already running, you will have to
destroy and recreate it to acquire the new updates in the box. The update
command just downloads these updates locally.

## Version Constraints

You can constrain a Vagrant environment to a specific version or versions
of a box using the [Vagrantfile](/docs/vagrantfile/) by specifying
the `config.vm.box_version` option.

If this option is not specified, the latest version is always used. This is
equivalent to specifying a constraint of ">= 0".

The box version configuration can be a specific version or a constraint of
versions. Constraints can be any combination of the following:
`= X`, `> X`, `< X`, `>= X`, `<= X`, `~> X`. You can combine multiple
constraints by separating them with commas. All the constraints should be
self explanatory except perhaps for `~>`, known as the "pessimistic constraint".
Examples explain it best: `~> 1.0` is equivalent to `>= 1.0, < 2.0`. And
`~> 1.1.5` is equivalent to `>= 1.1.5, < 1.2.0`.

You can choose to handle versions however you see fit. However, many boxes
in the public catalog follow [semantic versioning](http://semver.org/).
Basically, only the first number (the "major version") breaks backwards
compatibility. In terms of Vagrant boxes, this means that any software that
runs in version "1.1.5" of a box should work in "1.2" and "1.4.5" and so on,
but "2.0" might introduce big changes that break your software. By following
this convention, the best constraint is `~> 1.0` because you know it is safe
no matter what version is in that range.

Please note that, while the semantic versioning specification allows for
more than three points and pre-release or beta versions, Vagrant boxes must be
of the format `X.Y.Z` where `X`, `Y`, and `Z` are all positive integers.

## Automatic Update Checking

Using the [Vagrantfile](/docs/vagrantfile/), you can also configure
Vagrant to automatically check for updates during any `vagrant up`. This is
enabled by default, but can easily be disabled with
`config.vm.box_check_update = false` in your Vagrantfile.

When this is enabled, Vagrant will check for updates on every `vagrant up`,
not just when the machine is being created from scratch, but also when it
is resuming, starting after being halted, etc.

If an update is found, Vagrant will output a warning to the user letting
them know an update is available. That user can choose to ignore the warning
for now, or can update the box by running `vagrant box update`.

Vagrant can not and does not automatically download the updated box and
update the machine because boxes can be relatively large and updating the
machine requires destroying it and recreating it, which can cause important
data to be lost. Therefore, this process is manual to the extent that the
user has to manually enter a command to do it.

## Pruning Old Versions

Vagrant does not automatically prune old versions because it does not know
if they might be in use by other Vagrant environments. Because boxes can
be large, you may want to actively prune them once in a while using
`vagrant box remove`. You can see all the boxes that are installed
using `vagrant box list`.

Another option is to use `vagrant box prune` command to remove all installed boxes that are outdated and not currently in use.
