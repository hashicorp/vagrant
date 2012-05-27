---
layout: documentation
title: Documentation - Vagrantfile - config.ssh.timeout

current: Vagrantfile
---
# config.ssh.timeout

Configuration key: `config.ssh.timeout`

Default value: `10`

This is the timeout that Vagrant will use when attemping to make
any SSH connection. Despite hitting this timeout, Vagrant does attempt
to retry connections, but eventually if the timeout is continually
reached, an error will be shown.
