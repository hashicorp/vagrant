---
layout: "docs"
page_title: "vagrant resume - Command-Line Interface"
sidebar_current: "cli-resume"
description: |-
  The "vagrant resume" command is used to bring a machine back into the "up"
  state, perhaps if it was previously suspended via "vagrant halt" or "vagrant
  suspend".
---

# Resume

**Command: `vagrant resume [name|id]`**

This resumes a Vagrant managed machine that was previously suspended,
perhaps with the [suspend command](/docs/cli/suspend.html).

The configured provisioners will not run again, by default. You can force
the provisioners to re-run by specifying the `--provision` flag.

# Options

* `--provision` - Force the provisioners to run.

* `--provision-with x,y,z` - This will only run the given provisioners. For
  example, if you have a `:shell` and `:chef_solo` provisioner and run
  `vagrant provision --provision-with shell`, only the shell provisioner will
  be run.
