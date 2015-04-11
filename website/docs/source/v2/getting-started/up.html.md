---
page_title: "Up and SSH - Getting Started"
sidebar_current: "gettingstarted-up"
---

# Up And SSH

It is time to boot your first Vagrant environment. Run the following:

```
$ vagrant up
```

In less than a minute, this command will finish and you'll have a
virtual machine running Ubuntu. You won't actually _see_ anything though,
since Vagrant runs the virtual machine without a UI. To prove that it is
running, you can SSH into the machine:

```
$ vagrant ssh
```

This command will drop you into a full-fledged SSH session. Go ahead and
interact with the machine and do whatever you want. Although it may be tempting,
be careful about `rm -rf /`, since Vagrant shares a directory at `/vagrant`
with the directory on the host containing your Vagrantfile, and this can
delete all those files. Shared folders will be covered in the next section.

Take a moment to think what just happened: With just one line of configuration
and one command in your terminal, we brought up a fully functional, SSH accessible
virtual machine. Cool.

When you're done fiddling around with the machine, run `vagrant destroy`
back on your host machine, and Vagrant will remove all traces of the
virtual machine.

<a href="/v2/getting-started/boxes.html" class="button inline-button prev-button">Boxes</a>
<a href="/v2/getting-started/synced_folders.html" class="button inline-button next-button">Synced Folders</a>
