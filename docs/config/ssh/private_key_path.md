---
layout: documentation
title: Documentation - Vagrantfile - config.ssh.private_key_path

current: Vagrantfile
---
# config.ssh.private_key_path

Configuration key: `config.ssh.private_key_path`

Default value: `nil`

This is the path to the private key file used for SSH authentication.
Vagrant only supports publickey-based authentication for SSH. If this value
is a relative path, then it will be expanded relative to the location of
the main Vagrantfile. If this value is `nil`, then the default insecure
private key that ships with Vagrant will be used.
