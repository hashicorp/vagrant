---
layout: "docs"
page_title: "vagrant reload - Command-Line Interface"
sidebar_current: "cli-reload"
description: |-
  The "vagrant reload" command is the equivalent of running "vagrant halt"
  followed by "vagrant up".
---

# Reload

**Command: `vagrant reload [name|id]`**

The equivalent of running a [halt](/docs/cli/halt.html) followed by an
[up](/docs/cli/up.html).

This command is usually required for changes made in the Vagrantfile to
take effect. After making any modifications to the Vagrantfile, a `reload`
should be called.

The configured provisioners will not run again, by default. You can force
the provisioners to re-run by specifying the `--provision` flag.

# Options

* `--provision` - Force the provisioners to run.

* `--provision-with x,y,z` - This will only run the given provisioners. For
  example, if you have a `:shell` and `:chef_solo` provisioner and run
  `vagrant reload --provision-with shell`, only the shell provisioner will
  be run.
