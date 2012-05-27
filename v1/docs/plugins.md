---
layout: documentation
title: Documentation - Plugins

current: Plugins
---
# Plugins

Vagrant comes with many great features to get distributable development
environments up and running. But sometimes you need to change the way
Vagrant works or add new functionality which may or may not make sense
to merge back into Vagrant core. As of Vagrant 0.6, this problem is solved
through the use of _plugins_.

Plugins are powerful, first-class citizens which extend Vagrant using
an exposed and supported API. What can plugins do?

* Add new commands to the `vagrant` binary, such as `vagrant my_plugin`
* Modify the functionality of existing commands, such as adding new
  functionality when `vagrant up` is called.
* Add new configuration classes fr custom `config.my_plugin` style
  configuration in Vagrantfiles.

## Using Plugins

Installing plugins is a snap, and doesn't take more than a few
seconds.

Please refer to the documentation of any plugin you wish to use for
information on how to use it, but in general there are two methods
of installation:

1. Downloading a library or gem and manually `require`ing it in
   a project Vagrantfile.
2. Installing a gem which automatically hooks into Vagrant. With
   this option you don't have to do anything.

Please refer to any plugin's documentation for more information on
what you have to do.

## Developing Plugins

If you're interested in developing plugins, we've setup a comprehensive
set of documentation at [extending Vagrant](/docs/extending/index.html).
Also, if you run into any problems, please access any of our [support lines](/support.html)!
