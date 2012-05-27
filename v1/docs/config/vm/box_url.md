---
layout: documentation
title: Documentation - Vagrantfile - config.vm.box_url

current: Vagrantfile
---
# config.vm.box_url

Configuration key: `config.vm.box_url`

Default value: `nil`

This points to a valid URL to the box that the VM requires. This is
optional and is only used if the box doesn't already exist on the user's
system. If `vagrant up` is called and the box is not found, this value
is used to download the box.
