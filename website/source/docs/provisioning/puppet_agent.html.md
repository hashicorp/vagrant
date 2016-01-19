---
layout: "docs"
page_title: "Puppet Agent - Provisioning"
sidebar_current: "provisioning-puppetagent"
description: |-
  The Vagrant Puppet agent provisioner allows you to provision the guest using
  Puppet, specifically by calling "puppet agent", connecting to a Puppet master,
  and retrieving the set of modules and manifests from there.
---

# Puppet Agent Provisioner

**Provisioner name: `puppet_server`**

The Vagrant Puppet agent provisioner allows you to provision the guest using
[Puppet](https://www.puppetlabs.com/puppet), specifically by
calling `puppet agent`, connecting to a Puppet master, and retrieving
the set of modules and manifests from there.

<div class="alert alert-warning">
  <strong>Warning:</strong> If you are not familiar with Puppet and Vagrant already,
  I recommend starting with the <a href="/docs/provisioning/shell.html">shell
  provisioner</a>. However, if you are comfortable with Vagrant already, Vagrant
  is the best way to learn Puppet.
</div>

## Options

The `puppet_server` provisioner takes various options. None are strictly
required. They are listed below:

* `binary_path` (string) - Path on the guest to Puppet's `bin/` directory.

* `client_cert_path` (string) - Path to the client certificate for the
  node on your disk. This defaults to nothing, in which case a client
  cert will not be uploaded.

* `client_private_key_path` (string) - Path to the client private key for
  the node on your disk. This defaults to nothing, in which case a client
  private key will not be uploaded.

* `facter` (hash) - Additional Facter facts to make available to the
  Puppet run.

* `options` (string or array) - Additional command line options to pass
  to `puppet agent` when Puppet is ran.

* `puppet_node` (string) - The name of the node. If this is not set,
  this will attempt to use a hostname if set via `config.vm.hostname`.
  Otherwise, the box name will be used.

* `puppet_server` (string) - Hostname of the Puppet server. By default
  "puppet" will be used.

## Specifying the Puppet Master

The quickest way to get started with the Puppet agent provisioner is to just
specify the location of the Puppet master:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "puppet_server" do |puppet|
    puppet.puppet_server = "puppet.example.com"
  end
end
```

By default, Vagrant will look for the host named "puppet" on the
local domain of the guest machine.

## Configuring the Node Name

The node name that the agent registers as can be customized. Remember
this is important because Puppet uses the node name as part of the process
to compile the catalog the node will run.

The node name defaults to the hostname of the guest machine, but can
be customized using the Vagrantfile:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "puppet_server" do |puppet|
    puppet.puppet_node = "node.example.com"
  end
end
```

## Additional Options

Puppet supports a lot of command-line flags. Basically any setting can
be overridden on the command line. To give you the most power and flexibility
possible with Puppet, Vagrant allows you to specify custom command line
flags to use:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "puppet_server" do |puppet|
    puppet.options = "--verbose --debug"
  end
end
```
