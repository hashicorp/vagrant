---
layout: "intro"
page_title: "Up and SSH - Getting Started"
sidebar_current: "gettingstarted-up"
description: |-
  It is time to boot your first Vagrant environment. Run the following from your
  terminal - "vagrant up"
---

# Up And SSH

It is time to boot your first Vagrant environment. Run the following from your
terminal:

```
$ vagrant up
```

In less than a minute, this command will finish and you will have a
virtual machine running Ubuntu. You will not actually _see_ anything though,
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
virtual machine. Cool. The SSH session can be terminated with `CTRL+D`.

```
vagrant@precise64:~$ logout
Connection to 127.0.0.1 closed.
```

When you are done fiddling around with the machine, run `vagrant destroy`
back on your host machine, and Vagrant will terminate the use of any resources
by the virtual machine.

-> The `vagrant destroy` command does not actually remove the downloaded box
file. To _completely_ remove the box file, you can use the `vagrant box remove`
command.

## Next Steps

You have successfully created and interacted with your first Vagrant
environment! Read on to learn more about
[synced folders](/intro/getting-started/synced_folders.html).
