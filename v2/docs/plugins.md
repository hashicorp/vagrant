---
layout: v2_documentation
title: Documentation - Plugins

current: Plugins
---
# Plugins

Vagrant provides a fully supported plugin interface in order to allow
users to modify or extend the features of Vagrant. Plugins are powerful,
first-class citizens and even much of the core of Vagrant is
[built using plugins](https://github.com/mitchellh/vagrant/tree/master/plugins).
What can plugins do?

* Add new commands to the `vagrant` command, such as `vagrant my-great-plugin`
* Modify the functionality of existing commands, such as adding new
  behavior when `vagrant up` is called.
* Add new configuration classes so that your plugin can be configured
  using a Vagrantfile, for example with `config.my_plugin`.
* Add new provisioners, such as Chef or Puppet.
* Add new guest or host classes, so that Vagrant can work on new systems
  that the released version may not support yet.

For more information, read up on [how to use plugins](/v2/docs/plugins/using.html).

If you're interested in developing your own plugins, you'll want to
head over to the [writing plugins](/v2/docs/plugins/writing.html) page.
