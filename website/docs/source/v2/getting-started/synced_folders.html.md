---
page_title: "Synced Folders - Getting Started"
sidebar_current: "gettingstarted-syncedfolders"
---

# Synced Folders

While it is cool to have a virtual machine so easily, not many people
want to edit files using just plain terminal-based editors over SSH.
Luckily with Vagrant you don't have to. By using _synced folders_, Vagrant
will automatically sync your files to and from the guest machine.

By default, Vagrant shares your project directory (remember, that is the
one with the Vagrantfile) to the `/vagrant` directory in your guest machine.
Run `vagrant up` again and SSH into your machine to see:

```
$ vagrant up
...
$ vagrant ssh
...
vagrant@precise32:~$ ls /vagrant
Vagrantfile
```

Believe it or not, that Vagrantfile you see inside the virtual machine
is actually the same Vagrantfile that is on your actual host machine.
Go ahead and touch a file to prove it to yourself:

```
vagrant@precise32:~$ touch /vagrant/foo
vagrant@precise32:~$ exit
$ ls
foo Vagrantfile
```

Whoa! "foo" is now on your host machine. As you can see, Vagrant kept
the folders in sync.

With [synced folders](/v2/synced-folders/index.html), you can continue
to use your own editor on your host machine and have the files sync
into the guest machine.

<a href="/v2/getting-started/up.html" class="button inline-button prev-button">Up And SSH</a>
<a href="/v2/getting-started/provisioning.html" class="button inline-button next-button">Provisioning</a>
