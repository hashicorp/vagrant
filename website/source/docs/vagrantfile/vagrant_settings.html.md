---
layout: "docs"
page_title: "config.vagrant - Vagrantfile"
sidebar_current: "vagrantfile-vagrant"
description: |-
  The settings within "config.vagrant" modify the behavior of Vagrant
  itself.
---

# Vagrant Settings

**Config namespace: `config.vagrant`**

The settings within `config.vagrant` modify the behavior of Vagrant
itself.

## Available Settings

`config.vagrant.host` - This sets the type of host machine that is running
Vagrant. By default this is `:detect`, which causes Vagrant to auto-detect
the host. Vagrant needs to know this information in order to perform some
host-specific things, such as preparing NFS folders if they're enabled.
You should only manually set this if auto-detection fails.
