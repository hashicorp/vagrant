---
layout: "docs"
page_title: "Vagrant and Windows Subsystem for Linux"
sidebar_current: "other-wsl"
description: |-
  An overview of using Vagrant on Windows within the Windows Subsystem
  for Linux.
---

# Vagrant and Windows Subsystem for Linux

Windows has recently introduced a new feature called the Windows Subsystem
for Linux (WSL). This is a beta feature available in developer mode on recent
releases of Windows 10. It is important to note that this feature is still
in _beta_ on Windows, and Vagrant support should be considered _alpha_.

<div class="alert alert-warning">
  <strong>Warning: Advanced Topic!</strong> Using Vagrant within the Windows
  Subsystem for Linux is an advanced topic that only experienced Vagrant users
  who are reasonably comfortable with Windows, WSL, and Linux should approach.
</div>


# Installation

Installation requires WSL, Ubuntu on Windows, and Vagrant. Read on for installation
instructions for each item.

## Windows Subsystem for Linux and Ubuntu on Windows

First install the Windows Subsystem for Linux, followed by Ubuntu on Windows. This guide
from Microsoft walks through the process:

* https://msdn.microsoft.com/en-us/commandline/wsl/install_guide

## Vagrant Installation

Vagrant _must_ be installed within Ubuntu on Windows. Even though the `vagrant.exe`
file can be executed from within the WSL, it will not function as expected. To
install Vagrant into the WSL, follow these steps:

* Download the 64-bit Debian package from the downloads page.
* Open a `cmd` or `powershell` window
* Enter the command: `bash`
* Install vagrant: `sudo dpkg -i vagrant_VERSION_x86_64.deb`

```
C:\Users\vagrant> bash
vagrant@vagrant-10:/mnt/c/Users/vagrant$ sudo dpkg -i vagrant_VERSION_x86_64.deb
[sudo] password for vagrant:
(Reading database ... 31885 files and directories currently installed.)
Preparing to unpack vagrant_VERSION_x86_64.deb ...
Unpacking vagrant (1:VERSION) ...
Setting up vagrant (1:VERSION) ...
vagrant@vagrant-10:/mnt/c/Users/vagrant$ vagrant help
Usage: vagrant [options] <command> [<args>]
```

# Vagrant Usage

Vagrant will detect when it is being run within the WSL and adjust how it
locates and executes third party executables. For example, when using the
VirtualBox provider Vagrant will interact with VirtualBox installed on
the Windows system, not within the WSL. It is important to ensure that
any required Windows executable is available within your `PATH` to allow
Vagrant to access them.

## Windows Access

Working within the WSL provides a layer of isolation from the actual
Windows system. In some cases, a user may be using Vagrant in a regular
Windows environment, and then transition to using Vagrant within the
WSL. Using Vagrant within the WSL will appear to be isolated from
the Windows system. A new `VAGRANT_HOME` directory will be created within
the WSL (meaning all boxes will require re-downloading). Vagrant will also
lose the ability to control Vagrant managed machines within Windows (due
to user ID mismatches).

Vagrant supports enabling user access to provide seamless behavior and
control between Vagrant on Windows and Vagrant on WSL. By setting the
`VAGRANT_WSL_ACCESS_WINDOWS_USER` environment variable, Vagrant will
allow access to Vagrant managed machines in that user's home path in
Windows (`C:\Users\vagrant` for example), as well as share the `VAGRANT_HOME`
directory. Below is a demonstration of the behavior:

```
C:\Users\vagrant> bash
vagrant@vagrant-10:/mnt/c/Users/vagrant$ mkdir test
vagrant@vagrant-10:/mnt/c/Users/vagrant$ cd test
vagrant@vagrant-10:/mnt/c/Users/vagrant/test$ vagrant init hashicorp/precisec4
vagrant@vagrant-10:/mnt/c/Users/vagrant$ vagrant up
Vagrant will not operate outside the Windows Subsystem for Linux unless explicitly
instructed. Due to the inability to enforce expected Linux file ownership and
permissions on the Windows system, Vagrant will not make modifications to prevent
unexpected errors. To learn more about this, and the options that are available,
please refer to the Vagrant documentation:

  https://www.vagrantup.com/docs/other/wsl
vagrant@vagrant-10:/mnt/c/Users/vagrant$ export VAGRANT_WSL_ACCESS_WINDOWS_USER=vagrant
vagrant@vagrant-10:/mnt/c/Users/vagrant$ vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
```

It is important to note that file permissions cannot be enforced when Vagrant
modifies the Windows file system. It is for this reason that you must explicitly
enable this functionality with the express knowledge of the implication. If you
are unsure of how this may affect your system, do not enable this feature.

## Using Docker

The docker daemon cannot be run inside the Windows Subsystem for Linux. However,
the daemon _can_ be run on Windows and accessed by Vagrant while running in the
WSL. Once docker is installed and running on Windows, export the following
environment variable to give Vagrant access:

```
$ vagrant@vagrant-10:/mnt/c/Users/vagrant$ export DOCKER_HOST=tcp://127.0.0.1:2375
```
