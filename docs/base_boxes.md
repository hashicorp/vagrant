---
layout: documentation
title: Documentation - Base Boxes

current: Base Boxes
---
# Base Boxes

<div class="alert alert-block alert-notice">
  <h3>This topic is for advanced users</h3>
  <p>
    The following topic is for <em>advanced</em> users. The majority of Vagrant users
    will never have to do this. Therefore, only continue if you want to create a custom
    operating system. People wishing to distribute changes to an existing base box should
    see the <a href="/docs/getting-started/packaging.html">packaging guide</a>. If you
    continue with this guide, you will need a decent knowledge of the command line and
    the specific command line tools available on the system you are installing.
  </p>
</div>

There is a special category of boxes in Vagrant known as a "base boxes". These boxes
are ones which contain the bare bones necessary for Vagrant to function. The basic
requirements of a base box are as follows:

* VirtualBox Guest Additions for shared folders, port forwarding, etc.
* SSH with key-based auth support for the vagrant user
* Ruby & RubyGems to install Chef and Puppet
* Chef and Puppet for provisioning support

The above are absolutely _required_ of a base box in order to work properly with Vagrant.
The versions of those requirements however are up to you, as long as they are working properly.

<div class="alert alert-block alert-notice">
  <h3>What about password-based SSH? Why public/private keys?</h3>
  <p>
    While Vagrant was initially released with password-based SSH support, this proved
    to be difficult to support across multiple platforms. Instead, we switched to
    supporting only key-based authentication which has made cross platform support
    much easier.
  </p>
</div>

## Creating Base Boxes

### Creating and Configuring the Virtual Machine

Base boxes must be created using the [VirtualBox](http://www.virtualbox.org) tool
itself. This documentation will not cover the basics of setting up the virtual machine
except for some specific guidelines to follow:

* Make sure you allocate enough **disk space** in a **dynamically resizing drive**.
  Typically, we use a 40 GB drive, which is big enough for almost everything.
* Make sure the default memory allocation is _not too high_. Most people don't want
  to download a box to find it using 1 GB of RAM. We typically set it at 360 MB to
  start, since that is the size of most small slices. The RAM is configurable by the
  user at run-time using their [Vagrantfile](/docs/vagrantfile.html).
* Disable audio, usb, etc. controllers unless they're needed. Most applications
  don't need to play music! So save resources by disabling these features.

Now this is **really important**: Make sure the network controller is set to
**NAT**. For port forwarding to work properly, NAT must be used. Bridged
connects are not supported since it requires the machine to specify which
device it is bridged to, which is unknown.

Now go ahead and boot up the Virtual Machine, insert the DVD or attach the ISO file
you're installing the operating system from, and follow the install procedure.

<div class="alert alert-block alert-notice">
  <h3>Size does matter!</h3>
  <p>
    Having an environment you can send and have others boot up is really neat,
    but not very portable if your file is a 5 GB download. Even 1 GB is pushing
    the limits. You should aim for a final Box size of no more than 500 MB. In
    order to achieve that size, there is a few things you can do.
  </p>
  <ul>
    <li>Install the operating system without a GUI. That is, when prompted,
      deselect the option to install a desktop environment. On a Debian Lenny
      install, the final size difference between an OS with and without a
      desktop environment was a whole 1 GB.</li>
    <li>Clear the system cache before you export at the end. You don't need tmp
      files, or cached system packages. In the case of Debian or Ubuntu based
      operating systems, you can clean the cache with <code>apt-get clean</code>.</li>
    <li>Either keep RubyGems from installing documentation, using <code>--no-rdoc --no-ri</code>
      or consider removing all documentation afterwards using
      <code>rm -r "$(gem env gemdir)"/doc/*</code>.</li>
  </ul>
</div>

<div class="alert alert-block alert-notice">
  <h3>Convention over Configuration</h3>
  <p>
    Choice is a good thing, so just about everything in Vagrant can be changed.
    However, it's easier for others to use Vagrant when you follow a set of
    conventions. Now, while these aren't enforced conventions, if you plan to
    distribute the box, it is recommended you follow the following where possible:
  </p>
  <ul>
    <li>Hostname: vagrant-[os-name],  e.g.  vagrant-debian-lenny</li>
    <li>Domain: vagrantup.com</li>
    <li>Root Password: vagrant</li>
    <li>Main account login: vagrant</li>
    <li>Main account password: vagrant</li>
  </ul>
  <p>
    Also keep in mind that, in order to simplify configurations, Vagrant make
    assumptions about the main account login/password. It will assume the text
    'vagrant' for both values. If any of these are changed, you will need to
    remember to specify them in the Vagrantfile using the appropriate configuration
    methods before packaging the box.
  </p>
</div>

### Setup Permissions

Once the Virtual Machine is created, boot it up if it isn't already. Then let's
start by making sure the default account has proper permissions. Specifically,
the main user should have **password-less `sudo` privileges**. We do this by
running `su` and entering the root password you entered during the installation
of the operating system. Once logged in, run `visudo` and set the admin group
to use no password. Additionally, set the `env_keep` variable to `"SSH_AUTH_SOCK"`
so the connection to the forward agent is kept when `sudo` is run. That way
provisioners may run commands as other users and authenticate against the forward agent.

**Note:** Some bare bones systems will not include `sudo` by default. If `visudo`
is not an available command, install the `sudo` package for your operating system.

The line you should add in the `visudo` configuration to do that looks like this:

{% highlight bash %}
%admin ALL=NOPASSWD: ALL
{% endhighlight %}

Once that is setup, you may need to make the 'admin' group, and you then need to
assign the main user to that group (on Debian and Ubuntu systems, this is done with
the `groupadd` and `usermod` utilities. Consult the documentation for the commands your
operating system uses).

Then restart sudo using `/etc/init.d/sudo restart` (command may differ depending on
operating system). Finally, verify that sudo works without a password, but running
`exit` out of the root account, then `sudo which sudo`. You should get output similar
to `/usr/bin/sudo`.

<div class="alert alert-block alert-notice">
  <h3>Disable <code>requiretty</code></h3>
  <p>
    Some distros automatically enable <code>requiretty</code> within the sudo
    configuration. If so, there will be a line that looks like <code>Defaults requiretty</code>.
    Make sure this line is commented, otherwise Vagrant will fail.
  </p>
</div>

### Install VirtualBox Guest Additions

Now we have the permissions, let's gets shared folders and port forwarding working so we
can harness the full power Vagrant has to offer. There are various guides across the
internet explaining how to set up the Virtualbox Guest Additions, but for most unix-based
systems, the following will work just fine.

First, build the necessary packages. You may have to look these up for your system,
but they should be fairly similar. On Ubuntu and Debian based systems they are as follows:

{% highlight bash %}
$ sudo apt-get install linux-headers-$(uname -r) build-essential
{% endhighlight %}

Next, make sure to insert the guest additions image by using the GUI and clicking
on "Devices" followed by "Install Guest Additions.". Then run the following to
mount the CD Rom:

{% highlight bash %}
$ sudo mount /dev/cdrom /media/cdrom
{% endhighlight %}

And finally, run the shell script which matches your system. For linux on x86,
it is the following:

{% highlight bash %}
sudo sh /media/cdrom/VBoxLinuxAdditions.run
{% endhighlight %}

If you didn't install a Desktop environment when you installed the operating system,
as recommended to reduce size, the install of the VirtualBox additions should warn
you about the lack of OpenGL or Window System Drivers, but you can safely ignore this.

### Boot and Setup Basic Software

We need to setup the software Vagrant relies on. The _required_ software is listed below:

* **Ruby** - Use the dev package so mkmf is present for Chef to compile
* **RubyGems** - To install the Chef gem
* **Puppet** - To install Puppet
* **Chef** gem - For provisioning support (gem install chef)
* **SSH**

These are typically straightforward to install using the operating systems default package
management tools, so the details won't be gone into here. If prompted, make sure that the
SSH package is set to use **basic username/password authentication** and write down the
username/password for later.

### Configure SSH Authentication with a Public Key

Since Vagrant only supports key-based authentication for SSH, you must setup the SSH
user to use key-based authentication. This simply requires copying a public key into
`~/.ssh/authorized_keys`.

If you plan on distributing this base box as a public box, Vagrant provides an
"insecure" pair of public and private keys which are [available here](http://github.com/mitchellh/vagrant/tree/master/keys/).
By using the public key in that box, any Vagrant installation will automatically
be able to connect to your box since Vagrant defaults to using that insecure private
key.

If this box is meant to be private, we recommend you create your own custom
pair of keys and set that up. Users of your box can then specify the private key
you created by setting `config.ssh.private_key_path`.

<div class="alert alert-block alert-notice">
  <h3>Additional SSH Tweaks</h3>
  <p>
    In order to keep SSH access speedy even when your host computer can't
    access the internet, be sure to set <code>UseDNS</code> to <code>no</code>
    in <code>/etc/ssh/sshd_config</code>. This will disable DNS lookup of
    clients connecting to the server, which speeds up SSH connection.
  </p>
</div>

### Setup the Vagrantfile

By default, Vagrant only forwards SSH (from port 22 to 2222 with automatic port
collision fixing enabled). If you want to modify any defaults or add any other
ports to forward, you will have to package a Vagrantfile with your box. You can
create a Vagrantfile in any directory.

In the next section when the base box is packaged, it'll explain how to include
your custom Vagrantfile.

### Package and Distribute

Now that you have a completed virtual machine and possibly its accompanying
Vagrantfile, the final step is to package the contents into a "box" file and
distribute it. Packaging is done from Vagrant itself. Open a terminal and go
to the directory where your base box's Vagrantfile is, if you made one. If you
didn't make one, you can be in any directory.

Next, run `vagrant package`, specifying the name of the virtual machine in
VirtualBox that you want to package. If you created a custom Vagrantfile, don't
forget to add `--vagrantfile Vagrantfile` at the end of the following command as
well to include that in the package.

{% highlight bash %}
$ vagrant package --base my_base_box
{% endhighlight %}

This will take a few minutes, but the export will show you a progress bar. The
result is a file named `package.box` within the same directory which can be
distributed and installed by Vagrant users.

It would be a good idea to try and add this box to your own Vagrant installation,
setup a test environment, and try ssh in.

{% highlight bash %}
$ vagrant box add my_box package.box
$ mkdir test_environment
$ cd test_environment
$ vagrant init my_box
$ vagrant up
$ vagrant ssh
{% endhighlight %}
