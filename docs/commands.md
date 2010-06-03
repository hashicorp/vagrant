---
layout: documentation
title: Documentation - Commands
---
# Commands

The main interface to Vagrant is through the `vagrant` command line tools. `vagrant`
has many other subcommands which are invoked through it, for example `vagrant up` and
`vagrant package`. To learn about all the available subcommands through `vagrant`, simply
run `vagrant` alone:

{% highlight bash %}
$ vagrant
Usage: vagrant SUBCOMMAND
        --help                       Show help for the current subcommand.
        --version                    Output running Vagrant version.

Supported subcommands:
        box                 Box commands
        destroy             Destroys the vagrant environment
        halt                Halts the currently running vagrant environment
        init                Initializes current folder for Vagrant usage
        package             Packages a vagrant environment for distribution
        provision           Run the provisioner
        reload              Reload the vagrant environment
        resume              Resumes a suspend vagrant environment
        ssh                 SSH into the currently running environment
        ssh-config          outputs .ssh/config valid syntax for connecting to this environment via ssh
        status              Shows the status of the Vagrant environment.
        suspend             Suspends the currently running vagrant environment
        up                  Creates the vagrant environment

For help on a specific subcommand, run `vagrant SUBCOMMAND --help`
{% endhighlight %}

## Built-in Help

You can quickly and easily get help for any given command by simply adding the
`--help` flag to any command. This will save you the trip of coming to
this documentation page most of the time. Example:

{% highlight bash %}
$ vagrant package --help
Description: Packages a vagrant environment for distribution
Usage: vagrant package [--base BASE] [--include FILES]
        --help                       Show help for the current subcommand.
        --base [BASE]                Name or UUID of VM to create a base box from
        --include x,y,z              List of files to include in the package
{% endhighlight %}

<a name="vagrant-box"> </a>
## vagrant box

Boxes have their own section: [Vagrant Boxes](/docs/boxes.html)

<a name="vagrant-destroy"> </a>
## vagrant destroy

This destroys the vagrant environment by completely deleting the virtual machine
along with the hard drives attached to the virtual machine. `vagrant up` can then
be run again to rebuild the environment.

**Warning: This command _will_ delete all the data created within the machine.**

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

<a name="vagrant-provision"> </a>
## vagrant provision

Runs the provisioning scripts without reloading the entire Vagrant environment.
If you're just tweaking or adding some cookbooks, this command can save you a
lot of time.

Since this command doesn't reload the entire environment or reboot the VM,
it will not add new cookbooks folders if the cookbooks folder path changes. In
this case, please call `vagrant reload`.

<a name="vagrant-resume"> </a>
## vagrant resume

When you're ready to get rolling again its just as easy to start your virtual machine back up with
`vagrant resume`.

<a name="vagrant-ssh"> </a>
## vagrant ssh

Working from the command line inside your box is accomplished with a vanilla ssh connection. In fact
you could use ssh directly, but using `vagrant ssh` means you don't have to remember the login information
or what port ssh is forwarded to from your box. To learn more about those settings see the section on the [Vagrantfile](/docs/vagrantfile.html).
If you're box is booted simply run `vagrant ssh` from the root of your project directory.

<a name="vagrant-ssh-config"> </a>
## vagrant ssh-config

Although Vagrant provides direct access to SSH with the created environment via `vagrant ssh`, its
sometimes useful to be able to access the environment via a tool such as SCP or git, which requires
an entry in `.ssh/config`. `vagrant ssh-config` outputs a valid entry for `.ssh/config` which can
simply be appended to the file. Example output:

{% highlight bash %}
$ vagrant ssh-config
Host vagrant
  HostName localhost
  User vagrant
  Port 2222
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  IdentityFile /opt/local/lib/ruby/gems/1.8/gems/vagrant-0.3.0/keys/vagrant
{% endhighlight %}

Then, after putting this entry into my `.ssh/config`, I could do something like the following,
to show a single example:

{% highlight bash %}
$ scp vagrant:/vagrant/my_file.txt ~/Desktop/my_file.txt
{% endhighlight %}

<a name="vagrant-status"> </a>
## vagrant status

Its often hard to keep track and remember whether or not you brought up a virtual environment, shut
it down, suspended it, etc. `vagrant status` tells you the status of your current project's environment.

<a name="vagrant-suspend"> </a>
## vagrant suspend

When you're ready to call it quits for the day, there's no need to leave your Vagrant box soaking
up cpu cycles and memory. Simply issue `vagrant suspend` from your project root and VirtualBox will
take a snapshot of the box's current state from which you can resume later.

<a name="vagrant-up"> </a>
## vagrant up

This command builds the [Oracle VirtualBox](http://www.virtualbox.org) and sets it up based
on the specifications of the `Vagrantfile`. This command requires that the `Vagrantfile`,
in the very least, specify a box to use. The basic tasks handled by the up command are
listed below, not in any specific order:

* Build the VM based on the box
* Setup shared folders
* Setup forwarded ports
* Provision with chef (if configured)
* Boot in the background



