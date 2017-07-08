---
layout: "docs"
page_title: "Uninstalling Vagrant"
sidebar_current: "installation-uninstallation"
description: |-
  Uninstalling Vagrant is easy and straightforward. You can either uninstall
  the Vagrant binary, the user data, or both. The sections below cover how to
  do this on every platform.
---

# Uninstalling Vagrant

Uninstalling Vagrant is easy and straightforward. You can either uninstall
the Vagrant binary, the user data, or both. The sections below cover how to
do this on every platform.

## Removing the Vagrant Program

Removing the Vagrant program will remove the `vagrant` binary and all
dependencies from your machine. After uninstalling the program, you can
always [reinstall](/docs/installation/) again using standard
methods.

On **Windows**

> Uninstall using the add/remove programs section of the control panel

On **Mac OS X**:

```sh
rm -rf /opt/vagrant
rm -f /usr/local/bin/vagrant
sudo pkgutil --forget com.vagrant.vagrant
```

On **Linux**:

```sh
rm -rf /opt/vagrant
rm -f /usr/bin/vagrant
```

## Removing User Data

Removing the user data will remove all [boxes](/docs/boxes.html),
[plugins](/docs/plugins/), license files, and any stored state that may be used
by Vagrant. Removing the user data effectively makes Vagrant think it
is a fresh install.

On all platforms, remove the `~/.vagrant.d` directory to delete the user
data. When debugging, the Vagrant support team may ask you to remove this
directory. Before removing this directory, please make a backup.

Running Vagrant will automatically regenerate any data necessary to run,
so it is safe to remove the user data at any time.
