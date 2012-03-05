---
layout: documentation
title: Documentation - Vagrantfile - config.vagrant.dotfile_name

current: Vagrantfile
---
# config.vagrant.dotfile_name

Configuration key: `config.vagrant.dotfile_name`

Default value: `".vagrant"`

Vagrant puts a "dotfile" into each Vagrant-managed working directory
in order to keep track of some basic state of the virtual machine. By
default, this is named ".vagrant" and is not meant to be checked into
version control. You can control what the name of this file is using
this configuration value.
