---
layout: "docs"
page_title: "Chef Client - Provisioning"
sidebar_current: "provisioning-chefclient"
description: |-
  The Vagrant Chef Client provisioner allows you to provision the guest using
  Chef, specifically by connecting to an existing Chef Server and registering
  the Vagrant machine as a node within your infrastructure.
---

# Chef Client Provisioner

**Provisioner name: `chef_client`**

The Vagrant Chef Client provisioner allows you to provision the guest using
[Chef](https://www.chef.io/chef/), specifically by connecting
to an existing Chef Server and registering the Vagrant machine as a
node within your infrastructure.

If you are just learning Chef for the first time, you probably want
to start with the [Chef Solo](/docs/provisioning/chef_solo.html)
provisioner.

<div class="alert alert-warning">
  <strong>Warning:</strong> If you are not familiar with Chef and Vagrant already,
  I recommend starting with the <a href="/docs/provisioning/shell.html">shell
  provisioner</a>.
</div>

## Authenticating

The minimum required to use provision using Chef Client is to provide
a URL to the Chef Server as well as the path to the validation key so
that the node can register with the Chef Server:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "chef_client" do |chef|
    chef.chef_server_url = "http://mychefserver.com"
    chef.validation_key_path = "validation.pem"
  end
end
```

The node will register with the Chef Server specified, download the
proper run list for that node, and provision.

## Specifying a Run List

Normally, the Chef Server is responsible for specifying the run list
for the node. However, you can override what the Chef Server sends
down by manually specifying a run list:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "chef_client" do |chef|
    # Add a recipe
    chef.add_recipe "apache"

    # Or maybe a role
    chef.add_role "web"
  end
end
```

Remember, this will _override_ the run list specified on the Chef
server itself.

## Environments

You can specify the [environment](https://docs.chef.io/environments.html)
for the node to come up in using the `environment` configuration option:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "chef_client" do |chef|
    # ...

    chef.environment = "development"
  end
end
```

## Other Configuration Options

There are a few more configuration options available. These generally do not
need to be modified but are available if your Chef Server requires customization
of these variables.

* `client_key_path`
* `node_name`
* `validation_client_name`

In addition to all the options listed above, the Chef Client provisioner supports
the [common options for all Chef provisioners](/docs/provisioning/chef_common.html).

## Cleanup

When you provision your Vagrant virtual machine with Chef Server, it creates a
new Chef "node" entry and Chef "client" entry on the Chef Server, using the
hostname of the machine. After you tear down your guest machine, Vagrant can be
configured to do it automatically with the following settings:

```ruby
chef.delete_node = true
chef.delete_client = true
```

If you do not specify it or set it to `false`, you must explicitly delete these
entries from the Chef Server before you provision a new one with Chef Server.
For example, using Chef's built-in `knife` tool:

```
$ knife node delete precise64
$ knife client delete precise64
```

If you fail to do so, you will get the following error when Vagrant
tries to provision the machine with Chef Client:

```
HTTP Request Returned 409 Conflict: Client already exists.
```
