---
layout: "docs"
page_title: "Shell Scripts - Provisioning"
sidebar_current: "provisioning-shell"
description: |-
  The Vagrant Shell provisioner allows you to upload and execute a script within
  the guest machine.
---

# Shell Provisioner

**Provisioner name: `"shell"`**

The Vagrant Shell provisioner allows you to upload and execute a script within
the guest machine.

Shell provisioning is ideal for users new to Vagrant who want to get up
and running quickly and provides a strong alternative for users who are not
comfortable with a full configuration management system such as Chef or
Puppet.

For POSIX-like machines, the shell provisioner executes scripts with
SSH. For Windows guest machines that are configured to use WinRM, the
shell provisioner executes PowerShell and Batch scripts over WinRM.

## Options

The shell provisioner takes various options. One of `inline` or `path`
is required:

* `inline` (string) - Specifies a shell command inline to execute on the
  remote machine. See the [inline scripts](#inline-scripts) section below
  for more information.

* `path` (string) - Path to a shell script to upload and execute. It can be a
  script relative to the project Vagrantfile or a remote script (like a [gist](https://gist.github.com)).

The remainder of the available options are optional:

* `args` (string or array) - Arguments to pass to the shell script when executing it
  as a single string. These arguments must be written as if they were typed
  directly on the command line, so be sure to escape characters, quote,
  etc. as needed. You may also pass the arguments in using an array. In this
  case, Vagrant will handle quoting for you.

* `env` (hash) - List of key-value pairs to pass in as environment variables to
  the script. Vagrant will handle quoting for environment variable values, but
  the keys remain untouched.

* `binary` (boolean) - Vagrant automatically replaces Windows line endings with
  Unix line endings. If this is false, then Vagrant will not do this. By default
  this is "false". If the shell provisioner is communicating over WinRM, this
  defaults to "true".

* `privileged` (boolean) - Specifies whether to execute the shell script
  as a privileged user or not (`sudo`). By default this is "true". Windows
  guests use a scheduled task to run as a true administrator without the
  WinRM limitations.

* `upload_path` (string) - Is the remote path where the shell script will
  be uploaded to. The script is uploaded as the SSH user over SCP, so this
  location must be writable to that user. By default this is
  "/tmp/vagrant-shell". On Windows, this will default to
  "C:\tmp\vagrant-shell".

* `keep_color` (boolean) - Vagrant automatically colors output in green and
  red depending on whether the output is from stdout or stderr. If this is
  true, Vagrant will not do this, allowing the native colors from the script
  to be outputted.

* `name` (string) - This value will be displayed in the output so that
  identification by the user is easier when many shell provisioners are present.

* `powershell_args` (string) - Extra arguments to pass to `PowerShell`
  if you are provisioning with PowerShell on Windows.

* `powershell_elevated_interactive` (boolean) - Run an elevated script in interactive mode
  on Windows. By default this is "false". Must also be `privileged`. Be sure to
  enable auto-login for Windows as the user must be logged in for interactive
  mode to work.

* `md5` (string) - MD5 checksum used to validate remotely downloaded shell files.

* `sha1` (string) - SHA1 checksum used to validate remotely downloaded shell files.

<a name="inline-scripts"></a>
## Inline Scripts

Perhaps the easiest way to get started is with an inline script. An
inline script is a script that is given to Vagrant directly within
the Vagrantfile. An example is best:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "shell",
    inline: "echo Hello, World"
end
```

This causes `echo Hello, World` to be run within the guest machine when
provisioners are run.

Combined with a little bit more Ruby, this makes it very easy to embed
your shell scripts directly within your Vagrantfile. Another example below:

```ruby
$script = <<SCRIPT
echo I am provisioning...
date > /etc/vagrant_provisioned_at
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.provision "shell", inline: $script
end
```

I understand that if you are not familiar with Ruby, the above may seem very
advanced or foreign. But do not fear, what it is doing is quite simple:
the script is assigned to a global variable `$script`. This global variable
contains a string which is then passed in as the inline script to the
Vagrant configuration.

Of course, if any Ruby in your Vagrantfile outside of basic variable assignment
makes you uncomfortable, you can use an actual script file, documented in
the next section.

For Windows guest machines, the inline script _must_ be PowerShell. Batch
scripts are not allowed as inline scripts.

## External Script

The shell provisioner can also take an option specifying a path to
a shell script on the host machine. Vagrant will then upload this script
into the guest and execute it. An example:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "shell", path: "script.sh"
end
```

Relative paths, such as above, are expanded relative to the location
of the root Vagrantfile for your project. Absolute paths can also be used,
as well as shortcuts such as `~` (home directory) and `..` (parent directory).

If you use a remote script as part of your provisioning process, you can pass in
its URL as the `path` argument as well:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "shell", path: "https://example.com/provisioner.sh"
end
```

If you are running a Batch or PowerShell script for Windows, make sure
that the external path has the proper extension (".bat" or ".ps1"), because
Windows uses this to determine what kind of file it is to execute. If you
exclude this extension, it likely will not work.

To run a script already available on the guest you can use an inline script to
invoke the remote script on the guest.

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "shell",
    inline: "/bin/sh /path/to/the/script/already/on/the/guest.sh"
end
```

## Script Arguments

You can parameterize your scripts as well like any normal shell script.
These arguments can be specified to the shell provisioner. They should
be specified as a string as they'd be typed on the command line, so
be sure to properly escape anything:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "shell" do |s|
    s.inline = "echo $1"
    s.args   = "'hello, world!'"
  end
end
```

You can also specify arguments as an array if you do not want to worry about
quoting:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "shell" do |s|
    s.inline = "echo $1"
    s.args   = ["hello, world!"]
  end
end
```
