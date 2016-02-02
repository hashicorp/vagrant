---
layout: "docs"
page_title: "Synced Folders"
sidebar_current: "syncedfolder"
description: |-
  Synced folders enable Vagrant to sync a folder on the host machine to the
  guest machine, allowing you to continue working on your project's files
  on your host machine, but use the resources in the guest machine to
  compile or run your project.  
---

# Synced Folders

Synced folders enable Vagrant to sync a folder on the host machine to the
guest machine, allowing you to continue working on your project's files
on your host machine, but use the resources in the guest machine to
compile or run your project.

By default, Vagrant will share your project directory (the directory
with the [Vagrantfile](/docs/vagrantfile/)) to `/vagrant`.

Read the [basic usage](/docs/synced-folders/basic_usage.html) page to get started
with synced folders.
