---
layout: documentation
title: Documentation - Plugins
---
# Plugins

Vagrant does quite a bit out of the box, but sometimes you need Vagrant
to do more. A common example I use is for Ruby `rake` tasks (similar to
`make` tasks, but written in Ruby). Ruby projects use `rake` to do a variety
of things with their web projects, and Vagrant environments require the
developer to SSH into the instance, and run `rake` within the Vagrant VM.
A feature which doesn't quite fit into the core features of Vagrant but is
an ideal plugin is to add a command `vagrant rake` which simply passes the
arguments through to the VM, and outputs back on the host.

Vagrant plugins are very powerful, and can modify almost every part of
Vagrant:

* Add configuration classes for custom `config.my_plugin` in Vagrantfiles.
* Add new commands to the `vagrant` binary, such as `vagrant my_plugin`.
* Modify existing actions, such as the `up` or `destroy` action.

Plugins were added in Vagrant 0.6 and are still very new. As time goes
on, the API will be stabalized and more flexibility will be added. But
this is no reason to not start developing plugins right now, because you
should!

## How do plugins work?

So how do you make a Vagrant plugin? It really matters what you're
trying to achieve, but there are a couple ways you can go about doing it. Both
are outlined below with a brief how-to, pros, and cons.

### As a File

One option is to simply make your plugin a Ruby file (or files) which are
then loaded into your Vagrantfile. Just `require` this plugin file at the
top of your project's Vagrantfile. An example Vagrantfile which does
this is shown below:

{% highlight ruby %}
require 'my_plugin'

Vagrant::Config.run do |config|
  # ...
end
{% endhighlight %}

The pro of this is that you can distribute this plugin with your project,
and it is explicitly loaded in your Vagrantfile. The con is that you must
do this for every project.

### As a Gem

The second option is to make your plugin a Ruby gem. If the gem has the
file `vagrant_init.rb` anywhere on it's load path, Vagrant will automatically
load that file.

The pro of this is that it is global for every project, it is easy to
distribute your plugin, and it is easy to update it (simply update the
gem and ask users to download the new one). The con is that it is not
explicitly available for your project.

## Plugin Guidelines

These guidelines are listed before the various features plugins can
have because they're _very important_. Please follow them to be both a
good Vagrant citizen as well as a good Ruby citizen.

* If your plugin is a gem, please prefix the name with `vagrant-`. e.g. `vagrant-rake`.
  This is to avoid cluttering the gem namespace with small plugins to Vagrant.
* If you find yourself monkeypatching Vagrant in some way, [contact us](/support.html)
  and we'll work with you to get you an API.

## Plugin Features

TODO:

### Add a Configuration Class

### Add New Commands to `vagrant`

### Add or modify existing behavior
