---
layout: documentation
title: Documentation - Vagrantfile - config.vm.boot_mode

current: Vagrantfile
---
# config.vm.boot_mode

Configuration key: `config.vm.boot_mode`

Default value: `:headless`

Specifies the mode the VM is booted into. By default this is "headless"
which makes it so that the VM runs headless, or without a visible display.
This can also be changed to "gui" which will show a display. "gui" is useful
if you are debugging an issue with Vagrant or require a VM with a
windowing system that you can use.
