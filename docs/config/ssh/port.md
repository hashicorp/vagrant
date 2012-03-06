---
layout: documentation
title: Documentation - Vagrantfile - config.ssh.port

current: Vagrantfile
---
# config.ssh.port

Configuration key: `config.ssh.port`

Default value: `nil`

If this setting is set, then Vagrant will always use this as the SSH
port for the VM when attempting to connect from the host. Normally,
Vagrant attempts to auto-detect the SSH port of the VM, but if that isn't
working, this can be used to force Vagrant to a specific port.
