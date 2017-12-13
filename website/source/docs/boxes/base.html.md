---
layout: "docs"
page_title: "Creating a Base Box"
sidebar_current: "boxes-base"
description: |-
  There are a special category of boxes known as "base boxes." These boxes
  contain the bare minimum required for Vagrant to function, are generally
  not made by repackaging an existing Vagrant environment (hence the "base"
  in the "base box").
---

# Creating a Base Box

There are a special category of boxes known as "base boxes." These boxes
contain the bare minimum required for Vagrant to function, are generally
not made by repackaging an existing Vagrant environment (hence the "base"
in the "base box").

For example, the Ubuntu boxes provided by the Vagrant project (such as
"precise64") are base boxes. They were created from a minimal Ubuntu install
from an ISO, rather than repackaging an existing environment.

Base boxes are extremely useful for having a clean slate starting point from
which to build future development environments. The Vagrant project hopes
in the future to be able to provide base boxes for many more operating systems.
Until then, this page documents how you can create your own base box.

<div class="alert alert-warning">
  <strong>Advanced topic!</strong> Creating a base box can be a time consuming
  and tedious process, and is not recommended for new Vagrant users. If you are
  just getting started with Vagrant, we recommend trying to find existing
  base boxes to use first.
</div>

## What's in a Base Box?

A base box typically consists of only a bare minimum set of software
for Vagrant to function. As an example, a Linux box may contain only the
following:

* Package manager
* SSH
* SSH user so Vagrant can connect
* Perhaps Chef, Puppet, etc. but not strictly required.

In addition to this, each [provider](/docs/providers/) may require
additional software. For example, if you are making a base box for VirtualBox,
you will want to include the VirtualBox guest additions so that shared folders
work properly. But if you are making an AWS base box, this is not required.

## Creating a Base Box

Creating a base box is actually provider-specific. This means that depending
on if you are using VirtualBox, VMware, AWS, etc. the process for creating
a base box is different. Because of this, this one document cannot be a
full guide to creating a base box.

This page will document some general guidelines for creating base boxes,
however, and will link to provider-specific guides for creating base
boxes.

Provider-specific guides for creating base boxes are linked below:

* [Docker Base Boxes](/docs/docker/boxes.html)
* [Hyper-V Base Boxes](/docs/hyperv/boxes.html)
* [VMware Base Boxes](/docs/vmware/boxes.html)
* [VirtualBox Base Boxes](/docs/virtualbox/boxes.html)

### Packer and Vagrant Cloud

We strongly recommend using [Packer](https://www.packer.io) to create reproducible
builds for your base boxes, as well as automating the builds with
[Atlas](https://atlas.hashicorp.com). Read more about
[Creating Vagrant Boxes with Packer](https://www.terraform.io/docs/enterprise/packer/artifacts/creating-vagrant-boxes.html)
in the Atlas documentation.

### Disk Space

When creating a base box, make sure the user will have enough disk space
to do interesting things, without being annoying. For example, in VirtualBox,
you should create a dynamically resizing drive with a large maximum size.
This causes the actual footprint of the drive to be small initially, but
to dynamically grow towards the max size as disk space is needed, providing
the most flexibility for the end user.

If you are creating an AWS base box, do not force the AMI to allocate
terabytes of EBS storage, for example, since the user can do that on their
own. But you should default to mounting ephemeral drives, because they're
free and provide a lot of disk space.

### Memory

Like disk space, finding the right balance of the default amount of memory
is important. For most providers, the user can modify the memory with
the Vagrantfile, so do not use too much by default. It would be a poor
user experience (and mildly shocking) if a `vagrant up` from a base box
instantly required many gigabytes of RAM. Instead, choose a value such
as 512MB, which is usually enough to play around and do interesting things
with a Vagrant machine, but can easily be increased when needed.

### Peripherals (Audio, USB, etc.)

Disable any non-necessary hardware in a base box such as audio and USB
controllers. These are generally unnecessary for Vagrant usage and, again,
can be easily added via the Vagrantfile in most cases.

## Default User Settings

Just about every aspect of Vagrant can be modified. However, Vagrant does
expect some defaults which will cause your base box to "just work" out
of the box. You should create these as defaults if you intend to publicly
distribute your box.

If you are creating a base box for private use, you should try _not_ to
follow these, as they open up your base box to security risks (known
users, passwords, private keys, etc.).

### "vagrant" User

By default, Vagrant expects a "vagrant" user to SSH into the machine as.
This user should be setup with the
[insecure keypair](https://github.com/mitchellh/vagrant/tree/master/keys)
that Vagrant uses as a default to attempt to SSH. Also, even though
Vagrant uses key-based authentication by default, it is a general convention
to set the password for the "vagrant" user to "vagrant". This lets people
login as that user manually if they need to.

To configure SSH access with the insecure keypair, place the public
key into the `~/.ssh/authorized_keys` file for the "vagrant" user. Note
that OpenSSH is very picky about file permissions. Therefore, make sure
that `~/.ssh` has `0700` permissions and the authorized keys file has
`0600` permissions.

When Vagrant boots a box and detects the insecure keypair, it will
automatically replace it with a randomly generated keypair for additional
security while the box is running.

### Root Password: "vagrant"

Vagrant does not actually use or expect any root password. However, having
a generally well known root password makes it easier for the general public
to modify the machine if needed.

Publicly available base boxes usually use a root password of "vagrant" to
keep things easy.

### Password-less Sudo

This is **important!**. Many aspects of Vagrant expect the default SSH user
to have passwordless sudo configured. This lets Vagrant configure networks,
mount synced folders, install software, and more.

To begin, some minimal installations of operating systems do not even include
`sudo` by default. Verify that you install `sudo` in some way.

After installing sudo, configure it (usually using `visudo`) to allow
passwordless sudo for the "vagrant" user. This can be done with the
following line at the end of the configuration file:

```
vagrant ALL=(ALL) NOPASSWD: ALL
```

Additionally, Vagrant does not use a pty or tty by default when connected
via SSH. You will need to make sure there is no line that has `requiretty` in
it. Remove that if it exists. This allows sudo to work properly without a
tty. Note that you _can_ configure Vagrant to request a pty, which lets
you keep this configuration. But Vagrant by default does not do this.

### SSH Tweaks

In order to keep SSH speedy even when your machine or the Vagrant machine
is not connected to the internet, set the `UseDNS` configuration to `no`
in the SSH server configuration.

This avoids a reverse DNS lookup on the connecting SSH client which
can take many seconds.

## Windows Boxes

Supported Windows guest operating systems:
- Windows 7
- Windows 8
- Windows Server 2008
- Windows Server 2008 R2
- Windows Server 2012
- Windows Server 2012 R2

Windows Server 2003 and Windows XP are _not_ supported, but if you are a die
hard XP fan [this](https://stackoverflow.com/a/18593425/18475) may help you.

### Base Windows Configuration

  - Turn off UAC
  - Disable complex passwords
  - Disable "Shutdown Tracker"
  - Disable "Server Manager" starting at login (for non-Core)

In addition to disabling UAC in the control panel, you also must disable
UAC in the registry. This may vary from Windows version to Windows version,
but Windows 8/8.1 use the command below. This will allow some things like
automated Puppet installs to work within Vagrant Windows base boxes.

```
reg add HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /d 0 /t REG_DWORD /f /reg:64
```

### Base WinRM Configuration

To enable and configure WinRM you will need to set the WinRM service to
auto-start and allow unencrypted basic auth (obviously this is not secure).
Run the following commands from a regular Windows command prompt:

```
winrm quickconfig -q
winrm set winrm/config/winrs @{MaxMemoryPerShellMB="512"}
winrm set winrm/config @{MaxTimeoutms="1800000"}
winrm set winrm/config/service @{AllowUnencrypted="true"}
winrm set winrm/config/service/auth @{Basic="true"}
sc config WinRM start= auto
```

### Additional WinRM 1.1 Configuration

These additional configuration steps are specific to Windows Server 2008
(WinRM 1.1). For Windows Server 2008 R2, Windows 7 and later versions of
Windows you can ignore this section.

1. Ensure the Windows PowerShell feature is installed
2. Change the WinRM port to 5985 or upgrade to WinRM 2.0

The following commands will change the WinRM 1.1 port to what's expected by
Vagrant:

```
netsh firewall add portopening TCP 5985 "Port 5985"
winrm set winrm/config/listener?Address=*+Transport=HTTP @{Port="5985"}
```

## Other Software

At this point, you have all the common software you absolutely _need_ for
your base box to work with Vagrant. However, there is some additional software
you can install if you wish.

While we plan on it in the future, Vagrant still does not install Chef
or Puppet automatically when using those provisioners. Users can use a shell
provisioner to do this, but if you want Chef/Puppet to just work out of the
box, you will have to install them in the base box.

Installing this is outside the scope of this page, but should be fairly
straightforward.

In addition to this, feel free to install and configure any other software
you want available by default for this base box.

## Packaging the Box

Packaging the box into a `box` file is provider-specific. Please refer to
the provider-specific documentation for creating a base box. Some
provider-specific guides are linked to towards the top of this page.

## Distributing the Box

You can distribute the box file however you would like. However, if you want
to support versioning, putting multiple providers at a single URL, pushing
updates, analytics, and more, we recommend you add the box to
[HashiCorp's Vagrant Cloud](/docs/vagrant-cloud).

You can upload both public and private boxes to this service.

## Testing the Box

To test the box, pretend you are a new user of Vagrant and give it a shot:

```
$ vagrant box add --name my-box /path/to/the/new.box
...
$ vagrant init my-box
...
$ vagrant up
...
```

If you made a box for some other provider, be sure to specify the
`--provider` option to `vagrant up`. If the up succeeded, then your
box worked!
