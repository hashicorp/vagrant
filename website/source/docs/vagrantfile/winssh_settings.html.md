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

For more information, see the [Win32-OpenSSH project page](https://github.com/PowerShell/Win32-OpenSSH/).

# WinSSH Settings

The WinSSH communicator uses the same connection configuration options
as the SSH communicator. These settings provide the information for the
communicator to establish a connection to the VM.

The configuration options below are specific to the WinSSH communicator.

**Config namespace: `config.winssh`**

## Available Settings

* `config.winssh.forward_agent` (boolean) - If `true`, agent forwarding over SSH
connections is enabled. Defaults to false.

* `config.winssh.forward_env` (array of strings) - An array of host environment
variables to forward to the guest. If you are familiar with OpenSSH, this corresponds
to the `SendEnv` parameter.

    ```ruby
    config.winssh.forward_env = ["CUSTOM_VAR"]
    ```
* `config.winssh.proxy_command` (string) - A command-line command to execute that
receives the data to send to SSH on stdin. This can be used to proxy the SSH connection.
`%h` in the command is replaced with the host and `%p` is replaced with the port.

* `config.winssh.keep_alive` (boolean) - If `true`, this setting SSH will send keep-alive
packets every 5 seconds by default to keep connections alive.

* `config.winssh.shell` (string) - The shell to use when executing SSH commands from
Vagrant. By default this is `cmd`. Valid values are `"cmd"` or `"powershell"`.
When the WinSSH provider is enabled, this shell will be used when you run `vagrant ssh`.

* `config.winssh.export_command_template` (string) - The template used to generate
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

* `config.winssh.sudo_command` (string) - The command to use when executing a command
with `sudo`. This defaults to `%c` (assumes vagrant user is an administrator
and needs no escalation). The `%c` will be replaced by the command that is
being executed.

* `config.winssh.upload_directory` (string) - The upload directory used on the guest
to store scripts for execute. This is set to `C:\Windows\Temp` by default.
