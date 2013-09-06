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

## Additional Options

Puppet supports a lot of command-line flags. Basically any setting can
be overriden on the command line. To give you the most power and flexibility
possible with Puppet, Vagrant allows you to specify custom command line
flags to use:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "puppet" do |puppet|
    puppet.options = "--verbose --debug"
  end
end
```
