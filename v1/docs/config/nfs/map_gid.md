---
layout: documentation
title: Documentation - Vagrantfile - config.nfs.map_gid

current: Vagrantfile
---
# config.nfs.map_gid

Configuration key: `config.nfs.map_gid`

Default value: `:auto`

This configuration setting controls the global default NFS folder
GID mapping that is used. This should be set to an actual ID of a
group on your host machine, or `:auto`. If `:auto` is used, then Vagrant
will automatically determine the group ID of any NFS shared folder and
use that.
