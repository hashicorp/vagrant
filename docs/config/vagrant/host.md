---
layout: documentation
title: Documentation - Vagrantfile - config.vagrant.host

current: Vagrantfile
---
# config.vagrant.host

Configuration key: `config.vagrant.host`

Default value: `:detect`

There are some things that Vagrant does that requires some host-specific
behavior, such as exporting NFS shared folders. This sort of action differs
from Mac OS X to Linux. This configuration parameter tells Vagrant what sort
of host it is running on. By default, this is set to `:detect` and Vagrant
will do its best to figure out on its own. Available values that are built-in
to Vagrant are:

* `:arch`
* `:bsd`
* `:fedora`
* `:freebsd`
* `:gentoo`
* `:linux`
* `:opensuse`
* `:windows`

Note that some of the values overlap (such as `:linux` and `:fedora`). In these
cases, please pick the most accurate available value.
