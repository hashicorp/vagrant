---
sidebar_current: "cli-reload"
---

# Reload

**Command: `vagrant reload`**

The equivalent of running a [halt](/v2/cli/halt.html) followed by an
[up](/v2/cli/up.html).

This command is usually required for changes made in the Vagrantfile to
take effect. After making any modifications to the Vagrantfile, a `reload`
should be called.

# Options

* `--no-provision` - The provisioners will not run.

* `--provision-with x,y,z` - This will only run the given provisioners. For
  example, if you have a `:shell` and `:chef_solo` provisioner and run
  `vagrant provision --provision-with shell`, only the shell provisioner will
  be run.
