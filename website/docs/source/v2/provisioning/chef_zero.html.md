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

* `cookbooks_path` (string or array) - A list of paths to where cookbooks
  are stored. By default this is "cookbooks", expecting a cookbooks folder
  relative to the Vagrantfile location.

* `data_bags_path` (string) - A path where data bags are stored. By default, no
  data bag path is set.

* `environments_path` (string) - A path where environment definitions are
  located. By default, no environments folder is set.

* `environment` (string) - The environment you want the Chef run to be
  a part of. This requires Chef 11.6.0 or later, and that `environments_path`
  is set.

* `roles_path` (string or array) - A list of paths where roles are defined.
  By default this is empty. Multiple role directories are only supported by
  Chef 11.8.0 and later.

* `synced_folder_type` (string) - The type of synced folders to use when
  sharing the data required for the provisioner to work properly. By default
  this will use the default synced folder type. For example, you can set this
  to "nfs" to use NFS synced folders.


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
    chef.data_bags_path = "data_bags"
    chef.roles_path = "roles"

    # Add a recipe
    chef.add_recipe "apache"

    # Or maybe a role
    chef.add_role "web"
  end
end
```
