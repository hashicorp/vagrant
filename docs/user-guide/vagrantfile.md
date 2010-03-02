---
layout: guide
title: User Guide - Vagrantfile
---
# Vagrantfile

The Vagrantfile to Vagrant is just like what the Makefile is to the Make utility.
A single Vagrantfile exists at the root of every project which uses Vagrant, and
it is used to configure the virtual environment which Vagrant manages.

## Vagrantfile Load Order

Vagrant loads many Vagrantfiles whenever it is run, and the order they're loaded
determines the configuration values used. If there
are any configuration conflicts, the more recently loaded configuration
value overwrites the older value. Vagrant loads Vagrantfiles in the following order:

1. Vagrantfile from the gem directory is loaded. This contains all the defaults
  and should never be edited.
2. Vagrantfile from the box directory is loaded if a box is specified.
3. Vagrantfile from the project directory is loaded. This is typically the
  file that users will be touching.

Therefore, the Vagrantfile in the project directory overwrites any conflicting
configuration from a box which overwrites any conflicting configuration from
the default file.

## Vagrantfile Options

The Vagrantfile has many configurable options. To configure Vagrant, a configure
block must be created, which is passed in the configuration object. A brief example
is embedded below:

{% highlight ruby %}
Vagrant::Config.run do |config|
  # Use the config object to do any configuration:
  config.vm.box = "my_box"
end
{% endhighlight %}

There are many available configuration options. These are listed below: