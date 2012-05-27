---
layout: documentation
title: Documentation - Vagrantfile - config.vm.auto_port_range

current: Vagrantfile
---
# config.vm.auto_port_range

Configuration key: `config.vm.auto_port_range`

Default value: `2200..2250`

Forwarded ports defined for your VM can sometimes collide with
other VMs. For example, you might forward port 80 to 8080 in
multiple virtual machines. Vagrant has the ability to automatically
resolve forwarded port collisions for you when they're detected.
When these are resolved, it chooses a port from this configured
range. The value of this configuration parameter should be a
Ruby [Range](http://ruby-doc.org/core-1.9.3/Range.html) object.
