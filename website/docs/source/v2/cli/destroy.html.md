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

For linux-based guests, Vagrant uses the `shutdown` command to gracefully
terminate the machine. Due to the varying nature of operating systems, the
`shutdown` command may exist at many different locations in the guest's `$PATH`.
It is the guest machine's responsibility to properly populate the `$PATH` with
directory containing the `shutdown` command.

## Options

* `-f` or `--force` - Don't ask for confirmation before destroying.

<div class="alert alert-info">
    <p>
        The <code>vagrant destroy</code> command does not remove a box
        that may have been installed on your computer during <code>vagrant up</code>.
        Thus, even if you run <code>vagrant destroy</code>, the box installed in the system
        will still be present on the hard drive. To return your computer to the
        state as it was before <code>vagrant up</code> command, you need to use
        <code>vagrant box remove</code>. For more information, read about the
        <a href="/v2/cli/box.html">vagrant box remove</a> command.
    </p>
</div>
