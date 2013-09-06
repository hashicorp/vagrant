---
page_title: "vagrant destroy - Command-Line Interface"
sidebar_current: "cli-destroy"
---

# Destroy

**Command: `vagrant destroy`**

This command stops the running machine Vagrant is managing and
destroys all resources that were created during the machine creation process.
After running this command, your computer should be left at a clean state,
as if you never created the guest machine in the first place.

This command usually asks for confirmation before destroying. This
confirmation can be skipped by passing in the `-f` or `--force` flag.

## Options

* `-f` or `--force` - Don't ask for confirmation before destroying.
