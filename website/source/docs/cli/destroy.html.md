---
layout: "docs"
page_title: "vagrant destroy - Command-Line Interface"
sidebar_current: "cli-destroy"
description: |-
  The "vagrant destroy" command is used to stop the running virtual machine and
  terminate use of all resources that were in use by that machine.
---

# Destroy

**Command: `vagrant destroy [name|id]`**

This command stops the running machine Vagrant is managing and
destroys all resources that were created during the machine creation process.
After running this command, your computer should be left at a clean state,
as if you never created the guest machine in the first place.

For linux-based guests, Vagrant uses the `shutdown` command to gracefully
terminate the machine. Due to the varying nature of operating systems, the
`shutdown` command may exist at many different locations in the guest's `$PATH`.
It is the guest machine's responsibility to properly populate the `$PATH` with
directory containing the `shutdown` command.

## Options

* `-f` or `--force` - Do not ask for confirmation before destroying.
* `--[no-]parallel` - Destroys multiple machines in parallel if the provider
  supports it. Please consult the provider documentation to see if this feature
  is supported.

<div class="alert alert-info">
  The `destroy` command does not remove a box that may have been installed on
  your computer during `vagrant up`. Thus, even if you run `vagrant destroy`,
  the box installed in the system will still be present on the hard drive. To
  return your computer to the state as it was before `vagrant up` command, you
  need to use `vagrant box remove`.

  For more information, read about the
  <a href="/docs/cli/box.html">`vagrant box remove`</a> command.
</div>
