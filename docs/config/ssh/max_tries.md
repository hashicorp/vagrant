---
layout: documentation
title: Documentation - Vagrantfile - config.ssh.max_tries

current: Vagrantfile
---
# config.ssh.max_tries

Configuration key: `config.ssh.max_tries`

Default value: `100`

This is the maximum number of tries that Vagrant will attempt to
connect via SSH to the VM to determine when it is ready to communicate.
Once this threshold is reached, then commands such as `vagrant up`
will error saying that SSH on the VM never became ready.
