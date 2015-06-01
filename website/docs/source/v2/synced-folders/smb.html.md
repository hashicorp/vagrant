---
page_title: "SMB - Synced Folders"
sidebar_current: "syncedfolder-smb"
---

# SMB

**Synced folder type:** `smb`

Vagrant can use [SMB](http://en.wikipedia.org/wiki/Server_Message_Block)
as a mechanism to create a bi-directional synced folder between the host
machine and the Vagrant machine.

SMB is built-in to Windows machines and provides a higher performance
alternative to some other mechanisms such as VirtualBox shared folders.

<div class="alert alert-info">
	<p>
		<strong>Windows only!</strong> SMB is currently only supported
		when the host machine is Windows. The guest machine can be Windows
		or Linux.
	</p>
</div>

## Prerequisites

To use the SMB synced folder type, the machine running Vagrant must be
a Windows machine. In addition to this, the command prompt executing Vagrant
must have administrative privileges. Vagrant requires these privileges in
order to create new network folder shares.

The destination machine must be able to mount SMB filesystems. On Linux
the package to do this is usually called `smbfs` or `cifs`. Vagrant knows
how to automatically install this for some operating systems.

## Options

The SMB synced folder type has a variety of options it accepts:

* `smb_host` (string) - The host IP where the SMB mount is located. If this
  isn't specified, Vagrant will attempt to determine this automatically.

* `smb_password` (string) - The password used for authentication to mount
  the SMB mount. This is the password for the username specified by
  `smb_username`. If this is not specified, Vagrant will prompt you for it.
  It is highly recommended that you do not set this, since it would expose
  your password directly in your Vagrantfile.

* `smb_username` (string) - The username used for authentication to mount
  the SMB mount. This is the username to access the mount, _not_ the username
  of the account where the folder is being mounted to. This is usually your
  Windows username. If you sign into a domain, specify it as `user@domain`.
  If this option isn't specified, Vagrant will prompt you for it.

## Example

The following is an example of using SMB to sync a folder:

<pre class="prettyprint">
Vagrant.configure("2") do |config|
  config.vm.synced_folder ".", "/vagrant", type: "smb"
end
</pre>

## Limitations

Because SMB is a relatively new synced folder type in Vagrant, it still
has some rough edges. Hopefully, future versions of Vagrant will address
these.

The primary limitation of SMB synced folders at the moment is that they are
never pruned or cleaned up. Once the folder share is defined, Vagrant never
removes it. To clean up SMB synced folder shares, periodically run
`net share` in a command prompt, find the shares you don't want, then
run `net share NAME /delete` for each, where NAME is the name of the share.
