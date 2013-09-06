---
page_title: "config.ssh - Vagrantfile"
sidebar_current: "vagrantfile-ssh"
---

# SSH Settings

**Config namespace: `config.ssh`**

The settings within `config.ssh` relate to configuring how Vagrant
will access your machine over SSH. As with most Vagrant settings, the
defaults are typically fine, but you can fine tune whatever you'd like.

## Available Settings

`config.ssh.username` - This sets the username that Vagrant will SSH
as by default. Providers are free to override this if they detect a more
appropriate user. By default this is "vagrant," since that is what most
public boxes are made as.

<hr>

`config.ssh.host` - The hostname or IP to SSH into. By default this is
empty, because the provider usually figures this out for you.

<hr>

`config.ssh.port` - The port to SSH into. By default this is port 22.

<hr>

`config.ssh.guest_port` - The port on the guest that SSH is running on. This
is used by some providers to detect forwarded ports for SSH. For example, if
this is set to 22 (the default), and Vagrant detects a forwarded port to
port 22 on the guest from port 4567 on the host, Vagrant will attempt
to use port 4567 to talk to the guest if there is no other option.

<hr>

`config.ssh.private_key_path` - The path to the private key to use to
SSH into the guest machine. By default this is the insecure private key
that ships with Vagrant, since that is what public boxes use. If you make
your own custom box with a custom SSH key, this should point to that
private key.

<hr>

`config.ssh.forward_agent` - If `true`, agent forwarding over SSH
connections is enabled. Defaults to false.

<hr>

`config.ssh.forward_x11` - If `true`, X11 forwarding over SSH connections
is enabled. Defaults to false.

<hr>

`config.ssh.shell` - The shell to use when executing SSH commands from
Vagrant. By default this is `bash -l`. Note that this has no effect on
the shell you get when you run `vagrant ssh`. This configuration option
only affects the shell to use when executing commands internally in Vagrant.
