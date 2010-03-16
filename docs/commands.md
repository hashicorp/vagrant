---
layout: documentation
title: Documentation - Commands
---
# Commands

The main interface to Vagrant is through the `vagrant` command line tools. `vagrant`
is a "git-style" binary, meaning that it has various other binaries that are prefixed
with "vagrant" but can be used with a space between them. Let's take a look if at
all the vagrant binaries:

{% highlight bash %}
# Hitting tab to have our shell complete the filename with available binaries
$ vagrant
vagrant
vagrant-box
vagrant-down
vagrant-halt
vagrant-init
vagrant-package
vagrant-reload
vagrant-resume
vagrant-ssh
vagrant-suspend
vagrant-up
{% endhighlight %}

But just like git, we can use any of these tools by using a space instead of a
hyphen, so `vagrant init` is the same as `vagrant-init`.

Each binary has its own documentation associated with it as well. By running
`vagrant help COMMAND`, the documentation will show for the given command.
But we'll go over each binary here, as well.

<a name="vagrant-box"> </a>
## vagrant box

Boxes have their own section: [Vagrant Boxes](/docs/boxes.html)

<a name="vagrant-halt"> </a>
## vagrant halt

This halts the running virtual machine immediately by essentially "pulling the power."
It is a force shutdown. If possible, we recommend that virtual machines be shut down
gracefully by setting up a [rake task](/docs/rake.html) or using [`vagrant ssh`](#vagrant-ssh) to shut it down.

<a name="vagrant-init"> </a>
## vagrant init

This will probably be one of the first commands you ever run. `vagrant init` initializes
the current working directory as the root directory for a project which uses vagrant. It
does this by copying a default `Vagrantfile` into the current working directory.

The `Vagrantfile` is the configuration file using to specify the settings for the virtual
environment which Vagrant creates.

For more information regarding `Vagrantfile`s, read the entire section of the user
guide dedicated to the `Vagrantfile`.

<a name="vagrant-package"> </a>
## vagrant package

{% highlight bash %}
$ vagrant package [ output-file ] [ --include ]
{% endhighlight %}

Vagrant package brings together all the necessary files required for [VirtualBox](http://www.virtualbox.org) to create
and register an identical virtual environment for other projects or other machines. It is important to note
that if you intend to recreate an identical experience for another developer using Vagrant that the Vagrantfile
residing at the root of your project directory should be included, see [Vagrant Boxes](/docs/boxes.html#creating-a-box) for more information.

<a name="vagrant-resume"> </a>
## vagrant resume

When you're ready to get rolling again its just as easy to start your virtual machine back up with
`vagrant resume`.

<a name="vagrant-suspend"> </a>
## vagrant suspend

When you're ready to call it quits for the day, there's no need to leave your Vagrant box soaking
up cpu cycles and memory. Simply issue `vagrant suspend` from your project root and VirtualBox will
take a snapshot of the box's current state from which you can resume later.

<a name="vagrant-ssh"> </a>
## vagrant ssh

Working from the command line inside your box is accomplished with a vanilla ssh connection. In fact
you could use ssh directly, but using `vagrant ssh` means you don't have to remember the login information
or what port ssh is forwarded to from your box. To learn more about those settings see the section on the [Vagrantfile](/docs/vagrantfile.html).
If you're box is booted simply run `vagrant ssh` from the root of your project directory.

<a name="vagrant-up"> </a>
## vagrant up

This command builds the [Sun VirtualBox](http://www.virtualbox.org) and sets it up based
on the specifications of the `Vagrantfile`. This command requires that the `Vagrantfile`,
in the very least, specify a box to use. The basic tasks handled by the up command are
listed below, not in any specific order:

* Build the VM based on the box
* Setup shared folders
* Setup forwarded ports
* Provision with chef (if configured)
* Boot in the background



