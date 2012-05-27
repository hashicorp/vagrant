---
layout: documentation
title: Documentation - Vagrantfile - config.ssh.shell

current: Vagrantfile
---
# config.ssh.shell

Configuration key: `config.ssh.shell`

Default value: `"bash"`

Vagrant executes all SSH commands from within a login shell. This
configuration parameter tells Vagrant what login shell to use. This
shell must already be installed on the guest, and should be an
absolute path if the command isn't available by default on the
`$PATH`.
