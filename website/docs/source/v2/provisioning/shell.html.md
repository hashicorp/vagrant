---
page_title: "Shell Scripts - Provisioning"
sidebar_current: "provisioning-shell"
---

# Shell Provisioner

**Provisioner name: `"shell"`**

The shell provisioner allows you to upload and execute a script as
the root user within the guest machine.

Shell provisioning is ideal for users new to Vagrant who want to get up
and running quickly and provides a strong alternative for users who aren't
comfortable with a full configuration management system such as Chef or
Puppet.

## Options

The shell provisioner takes various options. One of `inline` or `path`
is required:

* `inline` (string) - Specifies a shell command inline to execute on the
  remote machine. See the [inline scripts](#inline-scripts) section below
  for more information.

* `path` (string) - Path to a shell script to upload and execute, relative
  to the project Vagrantfile.

The remainder of the available options are optional:

* `args` (string) - Arguments to pass to the shell script when executing it
  as a single string. These arguments must be written as if they were typed
  directly on the command line, so be sure to escape characters, quote,
  etc. as needed.

* `binary` (boolean) - Vagrant automatically replaces Windows line endings with
  Unix line endings. If this is true, then Vagrant will not do this. By default
  this is "false".

* `privileged` (boolean) - Specifies whether to execute the shell script
  as a privileged user or not (`sudo`). By default this is "true".

* `upload_path` (string) - Is the remote path where the shell script will
  be uploaded to. The script is uploaded as the SSH user over SCP, so this
  location must be writable to that user. By default this is "/tmp/vagrant-shell"

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

I understand if you're not familiar with Ruby, the above may seem very
advanced or foreign. But don't fear, what it is doing is quite simple:
the script is assigned to a global variable `$script`. This global variable
contains a string which is then passed in as the inline script to the
Vagrant configuration.

Of course, if any Ruby in your Vagrantfile outside of basic variable assignment
makes you uncomfortable, you can use an actual script file, documented in
the next section.

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
