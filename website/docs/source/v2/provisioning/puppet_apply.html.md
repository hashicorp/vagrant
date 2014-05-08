---
page_title: "Puppet Apply - Provisioning"
sidebar_current: "provisioning-puppetapply"
---

# Puppet Apply Provisioner

**Provisioner name: `puppet`**

The Puppet provisioner allows you to provision the guest using
[Puppet](http://www.puppetlabs.com/puppet), specifically by
calling `puppet apply`, without a Puppet Master.

<div class="alert alert-warn">
	<p>
		<strong>Warning:</strong> If you're not familiar with Puppet and Vagrant already,
		I recommend starting with the <a href="/v2/provisioning/shell.html">shell
		provisioner</a>. However, if you're comfortable with Vagrant already, Vagrant
		is the best way to learn Puppet.
	</p>
</div>

## Options

This section lists the complete set of available options for the Puppet
provisioner. More detailed examples of how to use the provisioner are
available below this section.

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

* `options` (array of strings) - Additionally options to pass to the
  Puppet executable when running Puppet.

* `synced_folder_type` (string) - The type of synced folders to use when
  sharing the data required for the provisioner to work properly. By default
  this will use the default synced folder type. For example, you can set this
  to "nfs" to use NFS synced folders.

* `temp_dir` (string) - The directory where all the data associated with
  the Puppet run (manifest files, modules, etc.) will be stored on the
  guest machine.

* `working_directory` (string) - Path in the guest that will be the working
  directory when Puppet is executed. This is usually only set because relative
  paths are used in the Hiera configuration.

## Bare Minimum

The quickest way to get started with the Puppet provisioner is to just
enable it:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "puppet"
end
```

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

Of course, you're able to put and name your manifests whatever you'd
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
won't attempt to upload the manifests directory. To specify a remote
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

## Modules

Vagrant also supports provisioning with [Puppet modules](http://docs.puppetlabs.com/guides/modules.html).
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

Custom facts to be exposed by [Facter](http://puppetlabs.com/puppet/related-projects/facter/)
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

[Hiera](http://docs.puppetlabs.com/hiera/1/) configuration is also supported.
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
