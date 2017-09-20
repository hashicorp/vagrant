---
layout: "docs"
page_title: "config.ssh - Vagrantfile"
sidebar_current: "vagrantfile-ssh"
description: |-
  The settings within "config.ssh" relate to configuring how Vagrant
  will access your machine over SSH. As with most Vagrant settings, the
  defaults are typically fine, but you can fine tune whatever you would like.
---

# SSH Settings

**Config namespace: `config.ssh`**

The settings within `config.ssh` relate to configuring how Vagrant
will access your machine over SSH. As with most Vagrant settings, the
defaults are typically fine, but you can fine tune whatever you would like.

## Available Settings

`config.ssh.username` - This sets the username that Vagrant will SSH
as by default. Providers are free to override this if they detect a more
appropriate user. By default this is "vagrant", since that is what most
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

`config.ssh.keys_only` - Only use Vagrant-provided SSH private keys (do not use
any keys stored in ssh-agent). The default value is `true`.

<hr>

`config.ssh.paranoid` - Perform strict host-key verification. The default value
is `false`.

<hr>

`config.ssh.forward_agent` - If `true`, agent forwarding over SSH
connections is enabled. Defaults to false.

<hr>

`config.ssh.forward_x11` - If `true`, X11 forwarding over SSH connections
is enabled. Defaults to false.

<hr>

`config.ssh.forward_env` - An array of host environment variables to forward to
the guest. If you are familiar with OpenSSH, this corresponds to the `SendEnv`
parameter.

```ruby
config.ssh.forward_env = ["CUSTOM_VAR"]
```

<hr>

`config.ssh.insert_key` - If `true`, Vagrant will automatically insert
a keypair to use for SSH, replacing Vagrant's default insecure key
inside the machine if detected. By default, this is true.

This only has an effect if you do not already use private keys for
authentication or if you are relying on the default insecure key.
If you do not have to care about security in your project and want to
keep using the default insecure key, set this to `false`.

<hr>

`config.ssh.proxy_command` - A command-line command to execute that receives
the data to send to SSH on stdin. This can be used to proxy the SSH connection.
`%h` in the command is replaced with the host and `%p` is replaced with
the port.

<hr>

`config.ssh.pty` - If `true`, pty will be used for provisioning. Defaults to false.

This setting is an _advanced feature_ that should not be enabled unless
absolutely necessary. It breaks some other features of Vagrant, and is
really only exposed for cases where it is absolutely necessary. If you can find
a way to not use a pty, that is recommended instead.

When pty is enabled, it is important to note that command output will _not_ be
streamed to the UI. Instead, the output will be delievered in full to the UI
once the command has completed.

<hr>

`config.ssh.keep_alive` If `true`, this setting SSH will send keep-alive packets
every 5 seconds by default to keep connections alive.

<hr>

`config.ssh.shell` - The shell to use when executing SSH commands from
Vagrant. By default this is `bash -l`. Note that this has no effect on
the shell you get when you run `vagrant ssh`. This configuration option
only affects the shell to use when executing commands internally in Vagrant.

<hr>

`config.ssh.export_command_template` - The template used to generate
exported environment variables in the active session. This can be useful
when using a Bourne incompatible shell like C shell. The template supports
two variables which are replaced with the desired environment variable key and
environment variable value: `%ENV_KEY%` and `%ENV_VALUE%`. The default template
is:

```ruby
config.ssh.export_command_template = 'export %ENV_KEY%="%ENV_VALUE%"'
```

`config.ssh.sudo_command` - The command to use when executing a command
with `sudo`. This defaults to `sudo -E -H %c`. The `%c` will be replaced by
the command that is being executed.

`config.ssh.compression` - If `false`, this setting will not include the
compression setting when ssh'ing into a machine. If this is not set, it will
default to `true` and `Compression=yes` will be enabled with ssh.

`config.ssh.dsa_authentication` - If `false`, this setting  will not include
`DSAAuthentication` when ssh'ing into a machine. If this is not set, it will
default to `true` and `DSAAuthentication=yes` will be used with ssh.

`config.ssh.extra_args` - This settings value is passed directly into the
ssh executable. This allows you to pass any arbitrary commands to do things such
as reverse tunneling down into the ssh program. These options can either be
single flags set as strings such as `"-6"` for IPV6 or an array of arguments
such as `["-L", "8008:localhost:80"]` for enabling a tunnel from host port 8008
to port 80 on guest.
