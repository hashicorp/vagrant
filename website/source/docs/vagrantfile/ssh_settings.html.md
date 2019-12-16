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

* `config.ssh.compression` (boolean) - If `false`, this setting will not include the
compression setting when ssh'ing into a machine. If this is not set, it will
default to `true` and `Compression=yes` will be enabled with ssh.

* `config.ssh.config` (string) - Path to a custom ssh_config file to use for configuring
the SSH connections.

* `config.ssh.dsa_authentication` (boolean) - If `false`, this setting  will not include
`DSAAuthentication` when ssh'ing into a machine. If this is not set, it will
default to `true` and `DSAAuthentication=yes` will be used with ssh.

* `config.ssh.export_command_template` (string) - The template used to generate
exported environment variables in the active session. This can be useful
when using a Bourne incompatible shell like C shell. The template supports
two variables which are replaced with the desired environment variable key and
environment variable value: `%ENV_KEY%` and `%ENV_VALUE%`. The default template
is:

    ```ruby
    config.ssh.export_command_template = 'export %ENV_KEY%="%ENV_VALUE%"'
    ```

* `config.ssh.extra_args` (array of strings) - This settings value is passed directly
into the ssh executable. This allows you to pass any arbitrary commands to do things such
as reverse tunneling down into the ssh program. These options can either be
single flags set as strings such as `"-6"` for IPV6 or an array of arguments
such as `["-L", "8008:localhost:80"]` for enabling a tunnel from host port 8008
to port 80 on guest.

* `config.ssh.forward_agent` (boolean) - If `true`, agent forwarding over SSH
connections is enabled. Defaults to false.

* `config.ssh.forward_env` (array of strings) - An array of host environment variables to
forward to the guest. If you are familiar with OpenSSH, this corresponds to the `SendEnv`
parameter.

    ```ruby
    config.ssh.forward_env = ["CUSTOM_VAR"]
    ```

* `config.ssh.forward_x11` (boolean) - If `true`, X11 forwarding over SSH connections
is enabled. Defaults to false.

* `config.ssh.guest_port` (integer) - The port on the guest that SSH is running on. This
is used by some providers to detect forwarded ports for SSH. For example, if
this is set to 22 (the default), and Vagrant detects a forwarded port to
port 22 on the guest from port 4567 on the host, Vagrant will attempt
to use port 4567 to talk to the guest if there is no other option.

* `config.ssh.host` (string) - The hostname or IP to SSH into. By default this is
empty, because the provider usually figures this out for you.

* `config.ssh.insert_key` (boolean) - By default or if set to `true`, Vagrant will automatically insert
a keypair to use for SSH, replacing Vagrant's default insecure key inside the machine
if detected. If you already use private keys for authentication to your guest, or are relying
on the default insecure key, this option will not be used. If set to `false`,
Vagrant will not automatically add a keypair to the guest.

* `config.ssh.keep_alive` (boolean) - If `true`, this setting SSH will send keep-alive packets
every 5 seconds by default to keep connections alive.

* `config.ssh.keys_only` (boolean) - Only use Vagrant-provided SSH private keys (do not use
any keys stored in ssh-agent). The default value is `true`.

* `config.ssh.paranoid` (boolean) - Perform strict host-key verification. The default value is
`false`.

    __Deprecation:__ The `config.ssh.paranoid` option is deprecated and will be removed
    in a future release. Please use the `config.ssh.verify_host_key` option instead.

* `config.ssh.password` (string) - This sets a password that Vagrant will use to
authenticate the SSH user. Note that Vagrant recommends you use key-based
authentication rather than a password (see `private_key_path`) below. If
you use a password, Vagrant will automatically insert a keypair if
`insert_key` is true.

* `config.ssh.port` (integer) - The port to SSH into. By default this is port 22.

* `config.ssh.private_key_path` (string, array of strings) - The path to the private
key to use to SSH into the guest machine. By default this is the insecure private key
that ships with Vagrant, since that is what public boxes use. If you make
your own custom box with a custom SSH key, this should point to that
private key. You can also specify multiple private keys by setting this to be an array.
This is useful, for example, if you use the default private key to bootstrap
the machine, but replace it with perhaps a more secure key later.

* `config.ssh.proxy_command` (string) - A command-line command to execute that receives
the data to send to SSH on stdin. This can be used to proxy the SSH connection.
`%h` in the command is replaced with the host and `%p` is replaced with
the port.

* `config.ssh.pty` (boolean) - If `true`, pty will be used for provisioning. Defaults to false.

    This setting is an _advanced feature_ that should not be enabled unless
    absolutely necessary. It breaks some other features of Vagrant, and is
    really only exposed for cases where it is absolutely necessary. If you can find
    a way to not use a pty, that is recommended instead.

    When pty is enabled, it is important to note that command output will _not_ be
    streamed to the UI. Instead, the output will be delivered in full to the UI
    once the command has completed.

* `config.ssh.remote_user` (string) - The "remote user" value used to replace the `%r`
character(s) used within a configured `ProxyCommand`. This value is only used by the
net-ssh library (ignored by the `ssh` executable) and should not be used in general.
This defaults to the value of `config.ssh.username`.

* `config.ssh.shell` (string) - The shell to use when executing SSH commands from
Vagrant. By default this is `bash -l`.

* `config.ssh.sudo_command` (string) - The command to use when executing a command
with `sudo`. This defaults to `sudo -E -H %c`. The `%c` will be replaced by
the command that is being executed.

* `config.ssh.username` (string) - This sets the username that Vagrant will SSH
as by default. Providers are free to override this if they detect a more
appropriate user. By default this is "vagrant", since that is what most
public boxes are made as.

* `config.ssh.verify_host_key` (string, symbol) - Perform strict host-key verification. The
default value is `:never`.
