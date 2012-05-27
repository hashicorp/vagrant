---
layout: documentation
title: Documentation - Vagrantfile - config.nfs.map_uid

current: Vagrantfile
---
# config.nfs.map_uid

Configuration key: `config.nfs.map_uid`

Default value: `:auto`

This configuration setting controls the global default NFS folder
UID mapping that is used. This should be set to an actual ID of a
user on your host machine, or `:auto`. If `:auto` is used, then Vagrant
will automatically determine the user ID of the owner of any NFS
shared folder and use that.
