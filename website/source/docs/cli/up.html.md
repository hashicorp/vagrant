---
layout: "docs"
page_title: "vagrant up - Command-Line Interface"
sidebar_current: "cli-up"
description: |-
  The "vagrant up" command is used to create, configuration, and provision a
  guest machine according to your Vagrantfile.
---

# Up

**Command: `vagrant up [name|id]`**

This command creates and configures guest machines according to your
[Vagrantfile](/docs/vagrantfile/).

This is the single most important command in Vagrant, since it is how
any Vagrant machine is created. Anyone using Vagrant must use this command
on a day-to-day basis.

## Options

* `--[no-]destroy-on-error` - Destroy the newly created machine if a fatal,
  unexpected error occurs. This will only happen on the first `vagrant up`.
  By default this is set.

* `--[no-]install-provider` - If the requested provider is not installed,
  Vagrant will attempt to automatically install it if it can. By default this
  is enabled.

* `--[no-]parallel` - Bring multiple machines up in parallel if the provider
  supports it. Please consult the provider documentation to see if this feature
  is supported.

* `--provider x` - Bring the machine up with the given
  [provider](/docs/providers/). By default this is "virtualbox".

* `--[no-]provision` - Force, or prevent, the provisioners to run.

* `--provision-with x,y,z` - This will only run the given provisioners. For
  example, if you have a `:shell` and `:chef_solo` provisioner and run
  `vagrant provision --provision-with shell`, only the shell provisioner will
  be run.
