---
layout: "docs"
page_title: "vagrant provision - Command-Line Interface"
sidebar_current: "cli-provision"
description: |-
  The "vagrant provision" command is used to run any provisioners configured
  for the guest machine, such as Puppet, Chef, Ansible, Salt, or Shell.
---

# Provision

**Command: `vagrant provision [vm-name]`**

Runs any configured [provisioners](/docs/provisioning/)
against the running Vagrant managed machine.

This command is a great way to quickly test any provisioners, and is especially
useful for incremental development of shell scripts, Chef cookbooks, or Puppet
modules. You can just make simple modifications to the provisioning scripts
on your machine, run a `vagrant provision`, and check for the desired results.
Rinse and repeat.

# Options

* `--provision-with x,y,z` - This will only run the given provisioners. For
  example, if you have a `:shell` and `:chef_solo` provisioner and run
  `vagrant provision --provision-with shell`, only the shell provisioner will
  be run.
