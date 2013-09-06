---
page_title: "Chef Client - Provisioning"
sidebar_current: "provisioning-chefclient"
---

# Chef Client Provisioner

**Provisioner name: `chef_client`**

The chef client provisioner allows you to provision the guest using
[Chef](http://www.opscode.com/chef/), specifically by connecting
to an existing Chef Server and registering the Vagrant machine as a
node within your infrastructure.

If you're just learning Chef for the first time, you probably want
to start with the [Chef Solo](/v2/provisioning/chef_solo.html)
provisioner.

<div class="alert alert-warn">
	<p>
		<strong>Warning:</strong> If you're not familiar with Chef and Vagrant already,
		I recommend starting with the <a href="/v2/provisioning/shell.html">shell
		provisioner</a>.
	</p>
</div>

## Authenticating

The minimum required to use provision using Chef client is to provide
a URL to the Chef sever as well as the path to the validation key so
that the node can register with the Chef server:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "chef_client" do |chef|
    chef.chef_server_url = "http://mychefserver.com:4000/"
    chef.validation_key_path = "validation.pem"
  end
end
```

The node will register with the Chef server specified, download the
proper run list for that node, and provision.

## Specifying a Run List

Normally, the Chef server is responsible for specifying the run list
for the node. However, you can override what the Chef server sends
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

You can specify the [environment](http://wiki.opscode.com/display/chef/Environments)
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

There are a few more configuration options available. These generally don't
need to be modified but are available if your Chef server requires customization
of these variables:

* `client_key_path`
* `node_name`
* `validation_client_name`

## Cleanup

When you provision your Vagrant virtual machine with Chef server, it creates a
new Chef "node" entry and Chef "client" entry on the Chef server, using the
hostname of the machine. After you tear down your guest machine, you must
explicitly delete these entries from the Chef server before you provision
a new one with Chef server. For example, using Chef's built-in `knife` tool:

```
$ knife node delete precise64
$ knife client delete precise64
```

If you fail to do so, you'll get the following error when Vagrant
tries to provision the machine with Chef client:

```
HTTP Request Returned 409 Conflict: Client already exists.
```
