---
layout: guide
title: User Guide - Commands
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

The commands are documented in the order "most useful" or "most used." While
this may be annoying for reference needs, the titles of each section are simply
the command, so you can easily use the browser search to find any command you're
looking for.

<a name="vagrant-init"> </a>
## vagrant init

This will probably be one of the first commands you ever run. `vagrant init` initializes
the current working directory as the root directory for a project which uses vagrant. It
does this by copying a default `Vagrantfile` into the current working directory.

The `Vagrantfile` is the configuration file using to specify the settings for the virtual
environment which Vagrant creates.

For more information regarding `Vagrantfile`s, read the entire section of the user
guide dedicated to the `Vagrantfile`.

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

<a name="vagrant-ssh"> </a>
## vagrant ssh

TODO