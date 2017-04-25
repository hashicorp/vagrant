---
layout: "intro"
page_title: "Synced Folders - Getting Started"
sidebar_current: "gettingstarted-syncedfolders"
description: |-
  While it is cool to have a virtual machine so easily, not many people
  want to edit files using just plain terminal-based editors over SSH.
  Luckily with Vagrant you do not have to. By using synced folders, Vagrant
  will automatically sync your files to and from the guest machine.
---

# Synced Folders

While it is cool to have a virtual machine so easily, not many people
want to edit files using just plain terminal-based editors over SSH.
Luckily with Vagrant you do not have to. By using _synced folders_, Vagrant
will automatically sync your files to and from the guest machine.

By default, Vagrant shares your project directory (remember, that is the
one with the Vagrantfile) to the `/vagrant` directory in your guest machine.

Note that when you `vagrant ssh` into your machine, you're in `/home/vagrant`.
`/home/vagrant` is a different directory from the synced `/vagrant` directory.

If your terminal displays an error about incompatible guest additions (or no
guest additions), you may need to update your box or choose a different box such
as `hashicorp/precise64`. Some users have also had success with the
[vagrant-vbguest](https://github.com/dotless-de/vagrant-vbguest) plugin, but it
is not officially supported by the Vagrant core team.

Run `vagrant up` again and SSH into your machine to see:

```
$ vagrant up
...
$ vagrant ssh
...
vagrant@precise64:~$ ls /vagrant
Vagrantfile
```

Believe it or not, that Vagrantfile you see inside the virtual machine
is actually the same Vagrantfile that is on your actual host machine.
Go ahead and touch a file to prove it to yourself:

```
vagrant@precise64:~$ touch /vagrant/foo
vagrant@precise64:~$ exit
$ ls
foo Vagrantfile
```

Whoa! "foo" is now on your host machine. As you can see, Vagrant kept
the folders in sync.

With [synced folders](/docs/synced-folders/), you can continue
to use your own editor on your host machine and have the files sync
into the guest machine.

## Next Steps

You have successfully interacted with your host machine via synced folders on
the guest machine. Read on to learn about installing packages, users, and more
with [provisioning](/intro/getting-started/provisioning.html).
