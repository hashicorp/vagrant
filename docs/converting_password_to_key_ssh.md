---
layout: documentation
title: Documentation - Converting to Key-Based SSH
---
# Converting Box to Key-Based SSH

With the release of Vagrant `0.2.x`, Vagrant no longer supports
password-based SSH. Previously, Vagrant _only_ supported password based SSH,
which means that every box built for `0.1.x` no longer works! But this isn't
a problem, since its _very easy_ to change the box to allow it to work with
key-based SSH.

<div class="info">
  <h3>We updated our boxes!</h3>
  <p>
    If you're not using a custom base box, and you're using one of the base
    boxes we created (<code>lucid32.box</code>, <code>lucid64.box</code>, etc.)
    then just remove your old box and download the new one. We updated all
    of our boxes to work with <code>0.2.x</code>!
  </p>
</div>

## Get Our Public Key

First, you need to download our [insecure public key](http://github.com/mitchellh/vagrant/raw/master/keys/vagrant.pub).
This is the public key which is used by public boxes, and will allow Vagrant
to automatically connect. If you want more security, you're welcome to use your
own public key, but to access the box you'll have to set the `config.ssh.private_key_path`
configuration value.

Save the public key somewhere familiar and easily accessible via the command
line, we'll use it in a moment.

## Up Your Environment

Next, `vagrant up` the environment which uses the broken box.
**This will fail on the "attempting to connect" step. This is okay!**

After the environment is "running," SCP the file to the new box, replacing
any of the details with their actual values (such as path to the public key,
SSH username, port, etc.):

{% highlight bash %}
$ scp -P 2222 /path/to/vagrant.pub vagrant@localhost:~
{% endhighlight %}

This will send the public key to the home directory on your box.

## Setup the Authorized Keys

You must now SSH in to your box. Yes, we know this doesn't work. You have
to do it manually:

{% highlight bash %}
$ ssh -p 2222 vagrant@localhost
{% endhighlight %}

The password is probably `vagrant`. If you're using some other custom box
and `vagrant` doesn't work, you'll have to consult its creator.

After SSHing in, run the following sequence of commands within the VM, which sets up
the authorized key file:

{% highlight bash %}
$ cd ~
$ mkdir .ssh
$ mv vagrant.pub .ssh/authorized_keys
$ chmod 0600 .ssh/authorized_keys
{% endhighlight %}

That's it! Log out and verify that `vagrant ssh` works.

## Repackage the Box

Finally, you probably want to repackage this box so you don't ever have to do
this again. This is easy as well. First, copy the Vagrantfile from the box to
your current project's directory (backing up your own Vagrantfile if necessary),
then package the box. Let's assume the box we're repackaging here is named `broken_box`:

{% highlight bash %}
$ cp ~/.vagrant.d/boxes/broken_box/Vagrantfile .
$ vagrant halt
$ vagrant package --include Vagrantfile
{% endhighlight %}

This should spit out a `package.box` file in the current working directory which
you can now re-add to your system and use. It should be a drop-in replacement for
your previously broken box.
