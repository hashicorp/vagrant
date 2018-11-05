---
layout: "docs"
page_title: "SMB - Synced Folders"
sidebar_current: "syncedfolder-smb"
description: |-
  Vagrant can use SMB as a mechanism to create a bi-directional synced folder
  between the host machine and the Vagrant machine.
---

# SMB

**Synced folder type:** `smb`

Vagrant can use [SMB](https://en.wikipedia.org/wiki/Server_Message_Block)
as a mechanism to create a bi-directional synced folder between the host
machine and the Vagrant machine.

SMB is built-in to Windows machines and provides a higher performance
alternative to some other mechanisms such as VirtualBox shared folders.

<div class="alert alert-info">
  SMB is currently only supported when the host machine is Windows or
  macOS. The guest machine can be Windows, Linux, or macOS.
</div>

## Prerequisites

### Windows Host

To use the SMB synced folder type on a Windows host, the machine must have
PowerShell version 3 or later installed. In addition, when Vagrant attempts
to create new SMB shares, or remove existing SMB shares, Administrator
privileges will be required. Vagrant will request these privileges using UAC.

### macOS Host

To use the SMB synced folder type on a macOS host, file sharing must be enabled
for the local account. Enable SMB file sharing by following the instructions
below:

* Open "System Preferences"
* Click "Sharing"
* Check the "On" checkbox next to "File Sharing"
* Click "Options"
* Check "Share files and folders using SMB"
* Check the "On" checkbox next to your username within "Windows File Sharing"
* Click "Done"

When Vagrant attempts to create new SMB shares, or remove existing SMB shares,
root access will be required. Vagrant will request these privileges using
`sudo` to run the `/usr/sbin/sharing` command. Adding the following to
the system's `sudoers` configuration will allow Vagrant to manage SMB shares
without requiring a password each time:

```
Cmnd_Alias VAGRANT_SMB_ADD = /usr/sbin/sharing -a * -S * -s * -g * -n *
Cmnd_Alias VAGRANT_SMB_REMOVE = /usr/sbin/sharing -r *
Cmnd_Alias VAGRANT_SMB_LIST = /usr/sbin/sharing -l
Cmnd_Alias VAGRANT_SMB_PLOAD = /bin/launchctl load -w /System/Library/LaunchDaemons/com.apple.smb.preferences.plist
Cmnd_Alias VAGRANT_SMB_DLOAD = /bin/launchctl load -w /System/Library/LaunchDaemons/com.apple.smbd.plist
Cmnd_Alias VAGRANT_SMB_DSTART = /bin/launchctl start com.apple.smbd
%admin ALL=(root) NOPASSWD: VAGRANT_SMB_ADD, VAGRANT_SMB_REMOVE, VAGRANT_SMB_LIST, VAGRANT_SMB_PLOAD, VAGRANT_SMB_DLOAD, VAGRANT_SMB_DSTART
```

### Guests

The destination machine must be able to mount SMB filesystems. On Linux
the package to do this is usually called `smbfs` or `cifs`. Vagrant knows
how to automatically install this for some operating systems.

## Options

The SMB synced folder type has a variety of options it accepts:

* `smb_host` (string) - The host IP where the SMB mount is located. If this
  is not specified, Vagrant will attempt to determine this automatically.

* `smb_password` (string) - The password used for authentication to mount
  the SMB mount. This is the password for the username specified by
  `smb_username`. If this is not specified, Vagrant will prompt you for it.
  It is highly recommended that you do not set this, since it would expose
  your password directly in your Vagrantfile.

* `smb_username` (string) - The username used for authentication to mount
  the SMB mount. This is the username to access the mount, _not_ the username
  of the account where the folder is being mounted to. This is usually your
  Windows username. If you sign into a domain, specify it as `user@domain`.
  If this option is not specified, Vagrant will prompt you for it.

## Example

The following is an example of using SMB to sync a folder:

```ruby
Vagrant.configure("2") do |config|
  config.vm.synced_folder ".", "/vagrant", type: "smb"
end
```

## Preventing Idle Disconnects

On Windows, if a file is not accessed for some period of time, it may
disconnect from the guest and prevent the guest from accessing the SMB-mounted
share. To prevent this, the following command can be used in a superuser
shell. Note that you should research if this is the right option for you.

```
net config server /autodisconnect:-1
```

## Common Issues

### "wrong fs type" Error

If during mounting on Linux you are seeing an error message that includes
the words "wrong fs type," this is because the SMB kernel extension needs to
be updated in the OS.

If updating the kernel extension is not an option, you can workaround the
issue by specifying the following options on your synced folder:

```ruby
mount_options: ["username=USERNAME","password=PASSWORD"]
```

Replace "USERNAME" and "PASSWORD" with your SMB username and password.

Vagrant 1.8 changed SMB mounting to use the more secure credential file
mechanism. However, many operating systems ship with an outdated filesystem
type for SMB out of the box which does not support this. The above workaround
reverts Vagrant to the insecure before, but causes it work.
