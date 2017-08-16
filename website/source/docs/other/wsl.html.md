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
Windows system. In most cases Vagrant will need access to the actual
Windows system to function correctly. As most Vagrant providers will
need to be installed on Windows directly (not within the WSL) Vagrant
will require Windows access. Access to the Windows system is controlled
via an environment variable: `VAGRANT_WSL_ENABLE_WINDOWS_ACCESS`. If
this environment variable is set, Vagrant will access the Windows system
to run executables and enable things like synced folders. When running
in a bash shell within WSL, the environment variable can be setup like so:

```
$ export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
```

This will enable Vagrant to access the Windows system outside of the
WSL and properly interact with Windows executables. This will automatically
modify the `VAGRANT_HOME` environment variable if it is not already defined,
setting it to be within the user's home directory on Windows.

It is important to note that paths shared with the Windows system will
not have Linux permissions enforced. For example, when a directory within
the WSL is synced to a guest using the VirtualBox provider, any local
permissions defined on that directory (or its contents) will not be
visible from the guest. Likewise, any files created from the guest within
the synced folder will be world readable/writeable in WSL.

Other useful WSL related environment variables:

* `VAGRANT_WSL_WINDOWS_ACCESS_USER` - Override current Windows username
* `VAGRANT_WSL_DISABLE_VAGRANT_HOME` - Do not modify the `VAGRANT_HOME` variable
* `VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH` - Custom Windows system home path

If a Vagrant project directory is not within the user's home directory on the
Windows system, certain actions that include permission checks may fail (like
`vagrant ssh`). When accessing Vagrant projects outside the WSL Vagrant will
skip these permission checks when the project path is within the path defined
in the `VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH` environment variable. For
example, if a user wants to run a Vagrant project from the WSL that is located
at `C:\TestDir\vagrant-project`:

```
C:\Users\vagrant> cd C:\TestDir\vagrant-project
C:\TestDir\vagrant-project> bash
vagrant@vagrant-10:/mnt/c/TestDir/vagrant-project$ export VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH="/mnt/c/TestDir"
vagrant@vagrant-10:/mnt/c/TestDir/vagrant-project$ vagrant ssh
```

## Using Docker

The docker daemon cannot be run inside the Windows Subsystem for Linux. However,
the daemon _can_ be run on Windows and accessed by Vagrant while running in the
WSL. Once docker is installed and running on Windows, export the following
environment variable to give Vagrant access:

```
vagrant@vagrant-10:/mnt/c/Users/vagrant$ export DOCKER_HOST=tcp://127.0.0.1:2375
```
