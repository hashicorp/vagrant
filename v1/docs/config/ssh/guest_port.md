---
layout: documentation
title: Documentation - Vagrantfile - config.ssh.guest_port

current: Vagrantfile
---
# config.ssh.guest_port

Configuration key: `config.ssh.guest_port`

Default value: `22`

This is the port of the SSH daemon on the guest. This value is used as
part of the process Vagrant uses to automatically detect the proper
host port that forwards to SSH. Part of these process is checking all
the forwarded ports for one which matches this guest port. If your box
uses a non-standard SSH port, you'll want to change this to some other
value.
