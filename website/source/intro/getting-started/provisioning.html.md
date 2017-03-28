---
layout: "intro"
page_title: "Provisioning - Getting Started"
sidebar_current: "gettingstarted-provisioning"
description: |-
  We have a virtual machine running a basic copy of Ubuntu and we can edit files
  from our machine and have them synced into the virtual machine. Let us now
  serve those files using a webserver.
---

# Provisioning

Alright, so we have a virtual machine running a basic copy of Ubuntu and
we can edit files from our machine and have them synced into the virtual machine.
Let us now serve those files using a webserver.

We could just SSH in and install a webserver and be on our way, but then
every person who used Vagrant would have to do the same thing. Instead,
Vagrant has built-in support for _automated provisioning_. Using this
feature, Vagrant will automatically install software when you `vagrant up`
so that the guest machine can be repeatably created and ready-to-use.

## Installing Apache

We will just setup [Apache](http://httpd.apache.org/) for our basic project,
and we will do so using a shell script. Create the following shell script
and save it as `bootstrap.sh` in the same directory as your Vagrantfile:

```bash
#!/usr/bin/env bash

apt-get update
apt-get install -y apache2
if ! [ -L /var/www ]; then
  rm -rf /var/www
  ln -fs /vagrant /var/www
fi
```

Next, we configure Vagrant to run this shell script when setting up
our machine. We do this by editing the Vagrantfile, which should now
look like this:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/precise64"
  config.vm.provision :shell, path: "bootstrap.sh"
end
```

The "provision" line is new, and tells Vagrant to use the `shell` provisioner
to setup the machine, with the `bootstrap.sh` file. The file path is relative
to the location of the project root (where the Vagrantfile is).

## Provision!

After everything is configured, just run `vagrant up` to create your
machine and Vagrant will automatically provision it. You should see
the output from the shell script appear in your terminal. If the guest
machine is already running from a previous step, run `vagrant reload --provision`,
which will quickly restart your virtual machine, skipping the initial
import step. The provision flag on the reload command instructs Vagrant to
run the provisioners, since usually Vagrant will only do this on the first
`vagrant up`.

After Vagrant completes running, the web server will be up and running.
You cannot see the website from your own browser (yet), but you can verify
that the provisioning works by loading a file from SSH within the machine:

```
$ vagrant ssh
...
vagrant@precise64:~$ wget -qO- 127.0.0.1
```

This works because in the shell script above we installed Apache and
setup the default `DocumentRoot` of Apache to point to our `/vagrant`
directory, which is the default synced folder setup by Vagrant.

You can play around some more by creating some more files and viewing
them from the terminal, but in the next step we will cover networking
options so that you can use your own browser to access the guest machine.

-> **For complex provisioning scripts**, it may be more efficient to package a
custom Vagrant box with those packages pre-installed instead of building them
each time. This topic is not covered by the getting started guide, but can be
found in the [packaging custom boxes](/docs/boxes/base.html) documentation.

## Next Steps

You have successfully provisioned your first virtual machine with Vagrant. Read
on to learn about [networking](/intro/getting-started/networking.html).
