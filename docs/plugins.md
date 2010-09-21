---
layout: documentation
title: Documentation - Plugins
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

For more information on how to use and write plugins, please see the
[extending Vagrant](/docs/extending/index.html) documentation.
