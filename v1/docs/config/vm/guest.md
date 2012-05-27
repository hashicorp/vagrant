---
layout: documentation
title: Documentation - Vagrantfile - config.vm.guest

current: Vagrantfile
---
# config.vm.guest

Configuration key: `config.vm.guest`

Default value: `:linux`

Some actions that Vagrant must do to the virtual machine require
operating system specific behavior, such as mounting shared folders
or configuring the network. Vagrant includes support for many well
known guest operating systems and this configuration option specifies
what guest OS will be installed. By default this is set to `:linux`.

For more information, please read the [documentation on guest-specific behavior](/docs/guests.html).
