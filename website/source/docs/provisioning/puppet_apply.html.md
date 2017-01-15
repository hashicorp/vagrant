---
layout: "docs"
page_title: "Puppet Apply - Provisioning"
sidebar_current: "provisioning-puppetapply"
description: |-
  The Vagrant Puppet provisioner allows you to provision the guest using
  Puppet, specifically by calling "puppet apply", without a Puppet Master.
---

# Puppet Apply Provisioner

**Provisioner name: `puppet`**

The Vagrant Puppet provisioner allows you to provision the guest using
[Puppet](https://www.puppetlabs.com/puppet), specifically by
calling `puppet apply`, without a Puppet Master.

<div class="alert alert-warning">
  <strong>Warning:</strong> If you are not familiar with Puppet and Vagrant already,
  I recommend starting with the <a href="/docs/provisioning/shell.html">shell
  provisioner</a>. However, if you are comfortable with Vagrant already, Vagrant
  is the best way to learn Puppet.
</div>

## Options

This section lists the complete set of available options for the Puppet
provisioner. More detailed examples of how to use the provisioner are
available below this section.

* `binary_path` (string) - Path on the guest to Puppet's `bin/` directory.

* `facter` (hash) - A hash of data to set as available facter variables
  within the Puppet run.

* `hiera_config_path` (string) - Path to the Hiera configuration on
  the host. Read the section below on how to use Hiera with Vagrant.

* `manifest_file` (string) - The name of the manifest file that will serve
  as the entrypoint for the Puppet run. This manifest file is expected to
  exist in the configured `manifests_path` (see below). This defaults
  to "default.pp"

* `manifests_path` (string) - The path to the directory which contains the
  manifest files. This defaults to "manifests"

* `module_path` (string) - Path, on the host, to the directory which
  contains Puppet modules, if any.

* `environment` (string) - Name of the Puppet environment.

* `environment_path` (string) - Path to the directory that contains environment
  files on the host disk.

* `environment_variables` (hash) - A hash of string key/value pairs to be set as
  environment variables before the puppet apply run.

* `options` (array of strings) - Additionally options to pass to the
  Puppet executable when running Puppet.

* `synced_folder_type` (string) - The type of synced folders to use when
  sharing the data required for the provisioner to work properly. By default
  this will use the default synced folder type. For example, you can set this
  to "nfs" to use NFS synced folders.

* `synced_folder_args` (array) - Arguments that are passed to the folder sync.
  For example ['-a', '--delete', '--exclude=fixtures'] for the rsync sync
  command.

* `temp_dir` (string) - The directory where all the data associated with
  the Puppet run (manifest files, modules, etc.) will be stored on the
  guest machine.

* `working_directory` (string) - Path in the guest that will be the working
  directory when Puppet is executed. This is usually only set because relative
  paths are used in the Hiera configuration.

~> If only `environment` and `environment_path` are specified, it will parse
and use the manifest specified in the `environment.conf` file. If
`manifests_path` and `manifest_file` is specified along with the environment
options, the manifest from the environment will be overridden by the specified `manifest_file`. If `manifests_path` and `manifest_file` are specified without
environments, the old non-environment mode will be used (which will fail on
Puppet 4+).

## Bare Minimum

The quickest way to get started with the Puppet provisioner is to just
enable it:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "puppet"
end
```

~> `puppet` need to be installed in the guest vm.

By default, Vagrant will configure Puppet to look for manifests in the
"manifests" folder relative to the project root, and will use the
"default.pp" manifest as an entry-point. This means, if your directory
tree looks like the one below, you can get started with Puppet with
just that one line in your Vagrantfile.

```
$ tree
.
|-- Vagrantfile
|-- manifests
|   |-- default.pp
```

## Custom Manifest Settings

Of course, you are able to put and name your manifests whatever you would
like. You can override both the directory where Puppet looks for
manifests with `manifests_path`, and the manifest file used as the
entry-point with `manifest_file`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "puppet" do |puppet|
    puppet.manifests_path = "my_manifests"
    puppet.manifest_file = "default.pp"
  end
end
```

The path can be relative or absolute. If it is relative, it is relative
to the project root.

You can also specify a manifests path that is on the remote machine
already, perhaps put in place by a shell provisioner. In this case, Vagrant
will not attempt to upload the manifests directory. To specify a remote
manifests path, use the following syntax:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "puppet" do |puppet|
    puppet.manifests_path = ["vm", "/path/to/manifests"]
    puppet.manifest_file = "default.pp"
  end
end
```

It is a somewhat odd syntax, but the tuple (two-element array) says
that the path is located in the "vm" at "/path/to/manifests".

## Environments

If you are using Puppet 4 or higher, you can provision using
[Puppet Environments](https://docs.puppetlabs.com/puppet/latest/reference/environments.html) by specifying the name of the environment and the path on the
local disk to the environment files:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "puppet" do |puppet|
    puppet.environment_path = "../puppet/environments"
    puppet.environment = "testenv"
  end
end
```

The default manifest is the environment's `manifests` directory.
If the environment has an `environment.conf` the manifest path is parsed
from there. Relative paths are assumed to be relative to the directory of
the environment. If the manifest setting in `environment.conf` use
the Puppet variables `$codedir` or `$environment` they are resoled to
the parent directory of `environment_path` and `environment` respectively.

## Modules

Vagrant also supports provisioning with [Puppet modules](https://docs.puppetlabs.com/guides/modules.html).
This is done by specifying a path to a modules folder where modules are located.
The manifest file is still used as an entry-point.

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "puppet" do |puppet|
    puppet.module_path = "modules"
  end
end
```

Just like the manifests path, the modules path is relative to the project
root if a relative path is given.

## Custom Facts

Custom facts to be exposed by [Facter](https://puppetlabs.com/facter)
can be specified as well:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "puppet" do |puppet|
    puppet.facter = {
      "vagrant" => "1"
    }
  end
end
```

Now, the `$vagrant` variable in your Puppet manifests will equal "1".

## Configuring Hiera

[Hiera](https://docs.puppetlabs.com/hiera/1/) configuration is also supported.
`hiera_config_path` specifies the path to the Hiera configuration file stored on
the host. If the `:datadir` setting in the Hiera configuration file is a
relative path, `working_directory` should be used to specify the directory in
the guest that path is relative to.

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "puppet" do |puppet|
    puppet.hiera_config_path = "hiera.yaml"
    puppet.working_directory = "/tmp/vagrant-puppet"
  end
end
```

`hiera_config_path` can be relative or absolute. If it is relative, it is
relative to the project root. `working_directory` is an absolute path within the
guest.

## Additional Options

Puppet supports a lot of command-line flags. Basically any setting can
be overridden on the command line. To give you the most power and flexibility
possible with Puppet, Vagrant allows you to specify custom command line
flags to use:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "puppet" do |puppet|
    puppet.options = "--verbose --debug"
  end
end
```
