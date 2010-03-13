---
layout: documentation
title: Documentation - Base Boxes
---
# Base Boxes

<div class="info">
  <h3>This topic is for advanced users</h3>
  <p>
    The following topic is for <em>advanced</em> users. The majority of Vagrant users
    will never have to do this. Therefore, only continue if you want to create a custom
    operating system. People wishing to distribute changes to an existing base box should
    see the <a href="/docs/getting-started/packaging.html">packaging guide</a>. If you
    continue with this guide, you will need a decent knowledge of the command line and
    the specific command lines tools available on the system you are installing.
  </p>
</div>

There are a special category of boxes in Vagrant known as a "base boxes". These boxes
are ones which contain the bare bones necessary for Vagrant to function. The basic
requirements of a base box are as follows:

* VirtualBox Guest Additions for shared folders, port forwarding, etc.
* SSH with key-based auth support for the vagrant user
* Ruby & RubyGems to install Chef
* Chef for provisioning support

The above are absolutely _required_ of a base box in order to work properly with Vagrant.
The versions of those requirements however are up to you, as long as they are working properly.

<div class="info">
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

<div class="info">
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
      operating systems, you can clean the cache with `apt-get clean`.</li>
    <li>Where possible, avoid installing all the documentation. When installing
      RubyGems for example, append `--no-rdoc --no-ri` to the install commands.</li>
  </ul>
</div>

<div class="info">
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
</div>

### Setup Permissions

Once the Virtual Machine is created, boot it up if it isn't already. Then lets
start by making sure the default account has proper permissions. Specifically,
the main user should have **password-less `sudo` privileges**. We do this by
running `su` and entering the root password you entered during the installation
of the operating system. Once logged in, run `visudo` and set the admin group
to use no password.

**Note:** Some bare bones systems will not include `sudo` by default. If `visudo`
is not an available command, install the `sudo` package for your operating system.

The line you should add in the `visudo` configuration to do that looks like this:

{% highlight bash %}
%admin ALL=NOPASSWD: ALL
{% endhighlight %}

Once that is setup, you may need to make the 'admin' group, and you then need to
assign the main user to that group (on Debian and Ubuntu systems, this is done with
the groupadd and usermod utilities. Consult the documentation for the commands your
operating system uses).

Then restart sudo using `/etc/init.d/sudo restart` (command may defer on operating systems).
Finally, verify that sudo works without a password, but running `exit` out of the root
account, then `sudo which sudo`. You should get output similar to `/usr/bin/sudo`.

### Install VirtualBox Guest Additions

Now we have the permissions, lets gets shared folders and port forwarding working so we
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
$ sudo mount /media/cdrom
{% endhighlight %}

And finally, run the shell script which matches your system. For linux on x86,
it is the following:

{% highlight bash %}
sudo sh /cdrom/VBoxLinuxAdditions-x86.run
{% endhighlight %}

If you didn't install a Desktop environment when you installed the operating system,
as recommended to reduce size, the install of the VirtualBox additions should warn
you about the lack of OpenGL or Window System Drivers, but you can safely ignore this.

### Boot and Setup Basic Software

We need to setup the software Vagrant relies on. The _required_ software is listed below:

* **Ruby** - Use the dev package so mkmf is present for Chef to compile
* **RubyGems** - To install the Chef gem
* **Chef** gem - For provisioning support (gem install chef)
* **SSH**

These are typically straightforward to install using the operating systems default package
management tools, so the details won't be gone into here. If promoted, make sure that the
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

### Copy the MAC Address

When the operating system was installed, it typically sets up the basic network devices
(eth0 and so on) automatically. This includes setting the MAC address of these devices.
Since configuring these network devices is often very OS-specific, instead of Vagrant
dynamically setting this at runtime, it forces VirtualBox to use a specific MAC address.

This requires little work on your end, but only needs to be done once per base box.
Simply run `sudo ifconfig` or the equivalent and copy the MAC address down somewhere on
your host machine. A screenshot of this is shown below:

![Copying MAC Address](/images/base_box_mac.jpg)

This MAC Address will be used soon. Go ahead and shutdown the virtual machine before continuing.

### Export the Virtual Machine

Next, export the virtual machine with "File" then "Export Appliance." Export it to
any folder, but make sure the filename is set to `box.ovf`, which is the Vagrant default.
You may actually name this ovf file anything you wish, but naming it the default has
no consequence and will make your life easier.

The export process can take several minutes. While that is running, you can progress
onto the next step.

### Setup the Vagrantfile

Create a Vagrantfile within the directory which contains the exported virtual
machine files (i.e. the directory with `box.ovf`). Then setup the contents of
the Vagrantfile. The following is what the contents of the Vagrantfile should
look like, well commented to explain each option:

{% highlight ruby %}
Vagrant::Config.run do |config|
  # Forward the SSH port. The 'forward_port_key' should match the
  # name of the forwarded port.
  config.ssh.forwarded_port_key = "ssh"
  config.vm.forward_port("ssh", 22, 2222)

  # The name of your OVF file. This probably won't need to be changed
  # if you exported as box.ovf
  config.vm.box_ovf = "box.ovf"

  # The MAC address which was copied earlier, without the colons ":"
  config.vm.base_mac = "0800279C2E42"
end
{% endhighlight %}

### Package and Distribute

Now that you have the exported virtual machine and the necessary Vagrantfile,
the final step is to package the contents into a "box" file and distribute it.
The format of "box" files is nothing special: they're simply tar files. The
biggest thing is to make sure that all the files in the archive are top-level,
meaning that the files aren't in a subdirectory.

<div class="info">
  <h3>Hold on, why not .gz, .bz2, or .7z ?!</h3>
  <p>
    Simple. When you export the virtual machine from VirtualBox, it is
    already compressed. Adding additional compression is slower and yields
    no smaller box size than just using tar.
  </p>
</div>

The following shows how to build the tar archive properly:

{% highlight bash %}
$ cd export_directory
$ ls
box.mf box.ovf drive.vmdk Vagrantfile
$ tar -cvf package.box ./*
{% endhighlight %}

As with the export, this can take several minutes. The result is a file called
`package.box` which can be distributed and installed by Vagrant users.

It would be a good idea to try and add this box to your own Vagrant installation,
setup a test environment, and try ssh in.

{% highlight bash %}
$ cd export_directory
$ vagrant box add my_box package.box
$ mkdir test_environment
$ cd test_environment
$ vagrant init
# open up Vagrantfile and set config.vm.box to 'my_box'
$ vagrant up
$ vagrant ssh
{% endhighlight %}
