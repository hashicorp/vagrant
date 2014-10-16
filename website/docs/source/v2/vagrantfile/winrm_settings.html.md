---
page_title: "config.winrm - Vagrantfile"
sidebar_current: "vagrantfile-winrm"
---

# WinRM Settings

**Config namespace: `config.winrm`**

The settings within `config.winrm` relate to configuring how Vagrant
will access your Windows guest over WinRM. As with most Vagrant settings, the
defaults are typically fine, but you can fine tune whatever you'd like.

These settings are only used if you've set your communicator type to `:winrm`.

## Available Settings

`config.winrm.username` - This sets the username that Vagrant will use
to login to the WinRM web service by default. Providers are free to override
this if they detect a more appropriate user. By default this is "vagrant,"
since that is what most public boxes are made as.

<hr>

`config.winrm.password` - This sets a password that Vagrant will use to
authenticate the WinRM user. By default this is "vagrant," since that is
what most public boxes are made as.

<hr>

`config.winrm.host` - The hostname or IP to SSH into. By default this is
empty, because the provider usually figures this out for you.

<hr>

`config.winrm.port` - The port to SSH into. By default this is port 22.

<hr>

`config.winrm.guest_port` - The port on the guest that SSH is running on. This
is used by some providers to detect forwarded ports for SSH. For example, if
this is set to 22 (the default), and Vagrant detects a forwarded port to
port 22 on the guest from port 4567 on the host, Vagrant will attempt
to use port 4567 to talk to the guest if there is no other option.

