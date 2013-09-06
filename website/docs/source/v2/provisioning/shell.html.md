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
