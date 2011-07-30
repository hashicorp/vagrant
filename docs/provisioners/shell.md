---
layout: documentation
title: Documentation - Provisioners - Shell
---
# Shell Provisioner

The shell provisioner is the most basic provisioner, and allows you to
upload and execute a shell script as the root user in the VM.

This is ideal for new users to Vagrant who don't want to deal with
the burden of learning an advanced system such as [Puppet](/docs/provisioners/puppet.html)
or [Chef](/docs/provisioners/chef_solo.html), or perhaps for users
who want to use this in addition to Chef or Puppet to perform some
task before or after that provisioner runs.

## Specifying the Path

This provisioner has one main configuration option: `path`. This
should be a path to the local shell script. This can be a relative
path, and if so, it will be expanded relative to the location of the
Vagrantfile. For the remainder of this page, lets assume we have a
file named `test.sh` in the same directory of the Vagrantfile with
the following contents:

{% highlight bash %}
#!/bin/bash

echo Hello, World!
{% endhighlight %}

To configure and run this provisioner, the following would be added
to the Vagrantfile:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :shell, :path => "test.sh"
end
{% endhighlight %}

This will cauase the `test.sh` file to be executed. Vagrant also shuttles
the stderr and stdout output to the host console for your convenience.

## Inline Scripts

If you have a quick, short script you want to execute, or perhaps your
script exists in a Ruby variable somehow in your Vagrantfile, you can
specify the script inline right in your Vagrantfile:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.provision :shell, :inline => "echo foo > /vagrant/test"
end
{% endhighlight %}

## Enabling and Executing

As with all other provisioners, adding the `config.vm.provision` line
to the Vagrantfile enables this provisioner. By running `vagrant up`,
`vagrant reload`, or `vagrant provision` (depending on the situation),
the provisioner will be executed.
