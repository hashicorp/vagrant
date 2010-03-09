---
layout: documentation
title: Documentation - Base Boxes
---
# Base Boxes

A special category known as "base boxes" are the boxes which contain
the bare bones necessary for Vagrant to function. The basic requirements
of the base box are the following:

* SSH with basic username/password SSH authentication
* Password-less `sudo`
* Ruby
* RubyGems
* Chef
* VirtualBox Guest Additions for shared folders, port forwarding, etc.

The above are absolutely _required_ by Vagrant to work properly with the
base box. The versions themselves are up to you as long as everything
(Ruby and Chef) work properly together.

**What about security?** A common question is "Why the password-less `sudo`?"
or "What about public/private keys?" Our answer to this is that since Vagrant
targets development environments, security is not a major concern, and we
currently value simplicity over it. In the future we may support keys, password
`sudo`, etc. but for now this is not possible with Vagrant.

**Note:** This topic is _advanced_ and in general most users of Vagrant will
never have to do this. This is only useful for those wishing to have custom
OS or custom version setups.

## Creating Base Boxes

### Creating and Configuring the Virtual Machine

Base boxes must be created using the [VirtualBox](http://www.virtualbox.org) tool
itself. Since we're working at such a "low level" relative to Vagrant, base boxes
must be created outside of Vagrant. This documentation will not cover the basics
of setting up the virtual machine except for some specific guidelines to follow:

* Make sure you allocate enough **disk space** in a **dynamically resizing drive**.
  Typically, we use a 40 GB drive, which is big enough for almost everything.
* Make sure the default memory allocation is _not too high_. Most people don't want
  to download a box to find it using 1 GB of RAM. We typically set it at 360 MB to
  start, since that is the size of most small slices. The RAM is configurable by the
  user at run-time using their Vagrantfile.
* Disable audio, usb, etc. controllers unless they're needed. Most web applications
  don't need to play music! Save resources by disabling these features.

Now this is **really important**: Make sure the network controller is set to
**NAT**. For port forwarding to work properly, NAT must be used. Bridged
connects are not supported since it requires the machine to specify which
device it is bridged to, which is unknown.

### Boot and Setup Basic Software

Once the VM is created, boot it up and setup the software you want. The
_required_ software is listed below:

* **Ruby** - For Chef
* **RubyGems** - For Chef
* **Chef** - For provisioning support.
* **SSH**

These are typically straightforward to install the details won't be gone
into here. Make sure that the SSH uses **basic username/password authentication**
and write down the username/password.

### Setup Permissions

After the software is setup, make sure the user has proper permissions. Specifically
the main user should have **password-less `sudo` priveleges**. We do this by
running `visudo` and setting the admin group to use no password. The line in the
`visudo` configuration looks like this:

{% highlight bash %}
%admin ALL=NOPASSWD: ALL
{% endhighlight %}

Once that is setup, be sure to add the main user to the `admin` group and verify
that sudo works without a password.

### Copy the MAC Address

When the OS installs, it typically sets up the basic network devices (eth0 and so on)
automatically. This includes setting the MAC address of these devices. Since configuring
these network devices is often very OS-specific, instead of Vagrant dynamically setting
this at runtime, it forces VirtualBox to use a specific MAC address. This requires
little work on your end. Simply run `ifconfig` or the equivalent and copy the
MAC address down somewhere on your host machine. A screenshot of this is shown
below:

![Copying MAC Address](/images/base_box_mac.jpg)

### Install VirtualBox Guest Additions

Finally, the box requires the VirtualBox guest additions. There are various guides
across the internet explaining how to set this up, but for most unix-based systems,
the following will work just fine.

First, build the necessary packages. You may have to look these up for your system,
but they should be fairly similar. On Ubuntu-based systems they are as follows:

{% highlight bash %}
$ sudo apt-get install linux-headers-$(uname -r) build-essential
{% endhighlight %}

Next, make sure to insert the guest additions image by using the GUI and clicking
on "Devices" followed by "Install Guest Additions." Once clicked, the device must
be mounted:

{% highlight bash %}
$ sudo mount /media/cdrom
$ cd /cdrom
{% endhighlight %}

And finally, run the shell script which matches your system. For linux on x86,
it is the following:

{% highlight bash %}
sudo sh VBoxLinuxAdditions-x86.run
{% endhighlight %}

The install will probably warn you about not installing OpenGL or Window System Drivers,
but this is okay. Once setup, shut down the VM.

### Export the Virtual Machine

Next, export the virtual machine with "File" then "Export Appliance." Export it to
any folder, but make sure the filename is set to `box.ovf`, which is the Vagrant default.
You may actually name this ovf file anything you wish, but naming it the default
has no consequence and will make your life easier.

### Setup the Vagrantfile

Create a Vagrantfile within the directory which contains the exported virtual
machine files (i.e. the directory with `box.ovf`). Then setup the contents of
the Vagrantfile. The following is what the contents of the Vagrantfile should
look like, well commented to explain each option:

{% highlight ruby %}
Vagrant::Config.run do |config|
  # SSH username
  config.ssh.username = "vagrant"

  # SSH password
  config.ssh.password = "vagrant"

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

With that done, the final step is to package the contents into a "box" file
and distribute it. The format of "box" files is nothing special: they're
simply tar files. The biggest thing is to make sure that all the files in the
archive are top-level, meaning that the files aren't in a subdirectory.

The following shows how to build the tar archive properly:

{% highlight bash %}
$ cd export_directory
$ ls
box.mf box.ovf drive.vmdk Vagrantfile
$ tar -cvf package.box ./*
{% endhighlight %}

The result is `package.box` which can be distributed and installed by
Vagrant user. Don't forget to test it yourself!