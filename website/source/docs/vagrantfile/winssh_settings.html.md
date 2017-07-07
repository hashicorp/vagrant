---
layout: "docs"
page_title: "config.winssh - Vagrantfile"
sidebar_current: "vagrantfile-winssh"
description: |-
  The settings within "config.winssh" relate to configuring how Vagrant
  will access your machine over Windows OpenSSH. As with most Vagrant settings, the
  defaults are typically fine, but you can fine tune whatever you would like.
---

# WinSSH

The WinSSH communicator is built specifically for the Windows native
port of OpenSSH. It does not rely on a POSIX-like environment which
removes the requirement of extra software installation (like cygwin)
for proper functionality.

_NOTE: The Windows native port of OpenSSH is still considered
"pre-release" and is non-production ready._

For more information, see the [Win32-OpenSSH project page](https://github.com/PowerShell/Win32-OpenSSH/).

# WinSSH Settings

The WinSSH communicator uses the same connection configuration options
as the SSH communicator. These settings provide the information for the
communicator to establish a connection to the VM.

**Config namespace: `config.ssh`**

The settings within `config.ssh` relate to configuring how Vagrant
will access your machine over SSH. As with most Vagrant settings, the
defaults are typically fine, but you can fine tune whatever you would like.

## Available Settings

`config.ssh.username` - This sets the username that Vagrant will SSH
as by default. Providers are free to override this if they detect a more
appropriate user. By default this is "vagrant," since that is what most
public boxes are made as.

<hr>

`config.ssh.password` - This sets a password that Vagrant will use to
authenticate the SSH user. Note that Vagrant recommends you use key-based
authentication rather than a password (see `private_key_path`) below. If
you use a password, Vagrant will automatically insert a keypair if
`insert_key` is true.

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

You can also specify multiple private keys by setting this to be an array.
This is useful, for example, if you use the default private key to bootstrap
the machine, but replace it with perhaps a more secure key later.

<hr>

`config.ssh.insert_key` - If `true`, Vagrant will automatically insert
a keypair to use for SSH, replacing Vagrant's default insecure key
inside the machine if detected. By default, this is true.

This only has an effect if you do not already use private keys for
authentication or if you are relying on the default insecure key.
If you do not have to care about security in your project and want to
keep using the default insecure key, set this to `false`.

<hr>

`config.ssh.keys_only` - Only use Vagrant-provided SSH private keys (do not use
any keys stored in ssh-agent). The default value is `true`.`

<hr>

`config.ssh.paranoid` - Perform strict host-key verification. The default value
is `false`.

# WinSSH Settings

The configuration options below are specific to the WinSSH communicator.

**Config namespace: `config.winssh`**

## Available Settings

`config.winssh.forward_agent` - If `true`, agent forwarding over SSH
connections is enabled. Defaults to false.

<hr>

`config.winssh.forward_env` - An array of host environment variables to forward to
the guest. If you are familiar with OpenSSH, this corresponds to the `SendEnv`
parameter.

```ruby
config.winssh.forward_env = ["CUSTOM_VAR"]
```

<hr>

`config.winssh.proxy_command` - A command-line command to execute that receives
the data to send to SSH on stdin. This can be used to proxy the SSH connection.
`%h` in the command is replaced with the host and `%p` is replaced with
the port.

<hr>

`config.winssh.keep_alive` If `true`, this setting SSH will send keep-alive packets
every 5 seconds by default to keep connections alive.

<hr>

`config.winssh.shell` - The shell to use when executing SSH commands from
Vagrant. By default this is `cmd`. Valid values are `"cmd"` or `"powershell"`.
Note that this has no effect on the shell you get when you run `vagrant ssh`.
This configuration option only affects the shell to use when executing commands
internally in Vagrant.

<hr>

`config.winssh.export_command_template` - The template used to generate
exported environment variables in the active session. This can be useful
when using a Bourne incompatible shell like C shell. The template supports
two variables which are replaced with the desired environment variable key and
environment variable value: `%ENV_KEY%` and `%ENV_VALUE%`. The default template
for a `cmd` configured shell is:

```ruby
config.winssh.export_command_template = 'set %ENV_KEY%="%ENV_VALUE%"'
```

The default template for a `powershell` configured shell is:

```ruby
config.winssh.export_command_template = '$env:%ENV_KEY%="%ENV_VALUE%"'
```

`config.winssh.sudo_command` - The command to use when executing a command
with `sudo`. This defaults to `%c` (assumes vagrant user is an administator
and needs no escalation). The `%c` will be replaced by the command that is
being executed.

<hr>

`config.winssh.upload_directory` - The upload directory used on the guest
to store scripts for execute. This is set to `C:\Windows\Temp` by default.
