---
page_title: "Chef Zero - Provisioning"
sidebar_current: "provisioning-chefzero"
---

# Chef Zero Provisioner

**Provisioner name: `chef_zero`**

The Chef Zero provisioner allows you to provision the guest using
[Chef](https://www.getchef.com/chef/), specifically with
[Chef Zero/local mode](https://docs.getchef.com/ctl_chef_client.html#run-in-local-mode).

This new provisioner is a middle ground between running a full blown
Chef Server and using the limited [Chef Solo](/v2/provisioning/chef_solo.html)
provisioner. It runs a local in-memory Chef Server and fakes the validation
and client key registration.

<div class="alert alert-warn">
  <p>
    <strong>Warning:</strong> If you're not familiar with Chef and Vagrant already,
    I recommend starting with the <a href="/v2/provisioning/shell.html">shell
    provisioner</a>. However, if you're comfortable with Vagrant already, Vagrant
    is the best way to learn Chef.
  </p>
</div>

## Options

This section lists the complete set of available options for the Chef Zero
provisioner. More detailed examples of how to use the provisioner are
available below this section.

* `nodes_path` (string) - A path where the Chef nodes are stored. Be default,
  no node path is set.

In addition to all the options listed above, the Chef Zero provisioner supports
the [common options for all Chef provisioners](/v2/provisioning/chef_common.html).

## Usage

The Chef Zero provisioner is configured basically the same way as the Chef Solo
provisioner. See the [Chef Solo documentations](/v2/provisioning/chef_solo.html)
for more information.

A basic example could look like this:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "chef_zero" do |chef|
    # Specify the local paths where Chef data is stored
    chef.cookbooks_path = "cookbooks"
    chef.roles_path = "roles"
    chef.nodes_path = "nodes"

    # Add a recipe
    chef.add_recipe "apache"

    # Or maybe a role
    chef.add_role "web"
  end
end
```
