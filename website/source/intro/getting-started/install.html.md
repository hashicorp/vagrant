---
layout: "intro"
page_title: "Install Vagrant - Getting Started"
sidebar_current: "gettingstarted-install"
description: |-
  Installing Vagrant is extremely easy. Head over to the Vagrant downloads page
  and get the appropriate installer or package for your platform. Install the
  package using standard procedures for your operating system.
---

# Install Vagrant

Vagrant must first be installed on the machine you want to run it on. To make
installation easy, Vagrant is distributed as a [binary package](/downloads.html)
for all supported platforms and architectures. This page will not cover how to
compile Vagrant from source, as that is covered in the
[README](https://github.com/mitchellh/vagrant/blob/master/README.md) and is only
recommended for advanced users.

## Installing Vagrant

To install Vagrant, first find the [appropriate package](/downloads.html) for
your system and download it. Vagrant is packaged as an operating-specific
package. Run the installer for your system. The installer will automatically add
`vagrant` to your system path so that it is available in terminals. If it is not
found, please try logging out and logging back in to your system (this is
particularly necessary sometimes for Windows).

## Verifying the Installation

After installing Vagrant, verify the installation worked by opening a new command prompt or console, and checking that `vagrant` is available:

```text
$ vagrant
Usage: vagrant [options] <command> [<args>]

    -v, --version                    Print the version and exit.
    -h, --help                       Print this help.

# ...
```

## Caveats

~> **Beware of system package managers!** Some operating system distributions
include a vagrant package in their upstream package repos. Please do not install
Vagrant in this manner. Typically these packages are missing dependencies or
include very outdated versions of Vagrant. If you install via your system's
package manager, it is very likely that you will experience issues. Please use
the official installers on the downloads page.

## Next Steps

You have successfully downloaded and installed Vagrant! Read on to learn about
[setting up your first Vagrant project](/intro/getting-started/project_setup.html).
