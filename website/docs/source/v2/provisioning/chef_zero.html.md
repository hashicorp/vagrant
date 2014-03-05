---
page_title: "Chef Zero - Provisioning"
sidebar_current: "provisioning-chefzero"
---

# Chef Zero Provisioner

**Provisioner name: `chef_zero`**

The chef zero provisioner allows you to provision the guest using the
local-mode of [Chef Client](/v2/provisioning/chef_client.html). It
specifically creates a local Chef Server and fakes the validation
and client key registration.

This new provisioner is a middle ground between running a full blown
Chef Server and using the limited [Chef Solo](/v2/provisioning/chef_solo.html)
provisioner.

<div class="alert alert-warn">
	<p>
		<strong>Warning:</strong> If you're not familiar with Chef and Vagrant already,
		I recommend starting with the <a href="/v2/provisioning/shell.html">shell
		provisioner</a>.
	</p>
</div>

## Specifying a Run List

When using [Chef Client](/v2/provisioning/chef_client.html) the Chef server is
responsible for specifying the run list for the node. Since Chef Zero uses a
local running Chef server if the node was not uploaded you're going to have
to override the run list:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "chef_zero" do |chef|
    # Add a recipe
    chef.add_recipe "apache"

    # Or maybe a role
    chef.add_role "web"
  end
end
```

## Environments

You can specify the [environment](http://wiki.opscode.com/display/chef/Environments)
for the node to come up in using the `environment` configuration option:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "chef_zero" do |chef|
    # ...

    chef.environment = "development"
  end
end
```
