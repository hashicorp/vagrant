---
layout: "docs"
page_title: "vagrant ssh-config - Command-Line Interface"
sidebar_current: "cli-ssh_config"
description: |-
  The "vagrant ssh-config" command is used to output a valid SSH configuration
  file capable of SSHing into the guest machine directly.
---

# SSH Config

**Command: `vagrant ssh-config [name|id]`**

This will output valid configuration for an SSH config file to SSH
into the running Vagrant machine from `ssh` directly (instead of
using `vagrant ssh`).

## Options

* `--host NAME` - Name of the host for the outputted configuration.
