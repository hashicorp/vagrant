---
page_title: "Vagrant 1.6 Feature Preview: Windows Guests"
title: "Feature Preview: Windows Guests"
author: "Mitchell Hashimoto"
author_url: https://github.com/mitchellh
---

Vagrant 1.6 will add a monumental feature to Vagrant: full Windows guest support.
The ability of Vagrant to manage Windows environments just as easy as
Linux environments has been requested for years and the time for
complete, official support has come.

Please don't mistake guest support for running Vagrant _on Windows_. Vagrant
has fully supported running on Windows for years, and works great. Vagrant
1.6 adds support for Vagrant to run Windows within the Vagrant environments
(in VirtualBox, Hyper-V, EC2, etc.).

The Windows guest support coming in Vagrant 1.6 allows you to spin up
Windows environments just as easily as you would Linux environments, and
lets you use PowerShell scripts, Chef, Puppet, etc. to install and configure
software.

And just as Linux has `vagrant ssh` as a first-class citizen, Windows
guests have `vagrant rdp`, which allow single-command access
to a complete remote desktop environment to your Windows environment.

Read on to learn more.

READMORE

### Demo

Seeing is believing, so we've prepared a couple videos below showing
how easy it is to use Vagrant with Windows guests.

<iframe src="//player.vimeo.com/video/92487440" width="680" height="382" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

<iframe src="//player.vimeo.com/video/92520901" width="680" height="382" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

### Windows

Windows is hugely popular and support for Windows development environments
has been the most requested feature by far for the recent year.

The Windows support is as easy to use as the Linux support: you just need
a box file that has Windows pre-installed, then you `vagrant up`. Synced
folders, networking, and provisioners all work.

Vagrant is able to communicate with Windows over either **SSH** or
**WinRM**. WinRM is more conventional, but if you have Cygwin installed with
an SSH server, Vagrant is able to use that too.

The support for WinRM is new in 1.6. For backwards compatibility reasons,
you must explicitly tell Vagrant when to use WinRM:

```
Vagrant.configure("2") do |config|
  # ...

  config.vm.communicator = "winrm"
end
```

That is the only change that is necessary for Vagrant to use Windows!
Vagrant will automatically detect that the operating system in its
environment is Windows, and will adapt accordingly.

Provisioners such as shell scripts, Chef, and Puppet are fully supported
and will run within Windows Vagrant environments. The shell provisioner
will run PowerShell and batch scripts if it is being used over WinRM.

### RDP

Accessing a Windows machine is unlike accessing a Linux machine. The
primary method for performing administrative tasks on Windows is via
[Remote Desktop](http://en.wikipedia.org/wiki/Remote_Desktop_Protocol).

For Linux, Vagrant provides `vagrant ssh` for one-command access to
the machine. We wanted to make accessing a Windows machine just as easy,
so we've created the `vagrant rdp` command. This command opens an RDP
client pre-configured to communicate to the Vagrant environment.

If SSH is available, `vagrant ssh` will still work for Windows.

To open a PowerShell or command prompt, use `vagrant rdp` to open the
remote desktop client, then open the appropriate console. This is the
conventional way to work with remote Windows machines.

### Thanks vagrant-windows!

Early in the Vagrant 1.6 development process,
[Shawn Neal](https://github.com/sneal) and
[Paul Morton](https://github.com/pmorton) became core committers to
Vagrant. These are two of the brains behind
[vagrant-windows](https://github.com/WinRb/vagrant-windows), an impressive
Vagrant plugin that has been unofficially bringing Windows guest
support to Vagrant for years.

The core of the Windows support presented in this feature preview
today has been from reintegrating vagrant-windows into Vagrant itself.
Supporting Windows in such a smooth way wouldn't have been possible
without the work done by these folks, and the public should know of
their contribution.

Thank you vagrant-windows team!

### Next

This is a huge milestone for Vagrant. At least one person at every
conference talk given by myself in the past two years has asked me when Vagrant
will support Windows. I'm excited to finally be able to say "it does now!"

Next week we'll continue this series with another feature preview.
The feature we'll be covering next week is a fun one.
