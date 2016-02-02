---
layout: "docs"
page_title: "Chef Solo - Provisioning"
sidebar_current: "provisioning-chefsolo"
description: |-
  The Vagrant Chef Solo provisioner allows you to provision the guest using
  Chef, specifically with chef-solo.
---

# Chef Solo Provisioner

**Provisioner name: `chef_solo`**

The Vagrant Chef Solo provisioner allows you to provision the guest using
[Chef](https://www.chef.io/chef/), specifically with
[Chef Solo](https://docs.chef.io/chef_solo.html).

Chef Solo is ideal for people who are already experienced with Chef,
already have Chef cookbooks, or are looking to learn Chef. Specifically,
this documentation page will not go into how to use Chef or how to write
Chef cookbooks, since Chef is a complete system that is beyond the scope
of a single page of documentation.

<div class="alert alert-warning">
  <strong>Warning:</strong> If you are not familiar with Chef and Vagrant already,
  I recommend starting with the <a href="/docs/provisioning/shell.html">shell
  provisioner</a>. However, if you are comfortable with Vagrant already, Vagrant
  is the best way to learn Chef.
</div>

## Options

This section lists the complete set of available options for the Chef Solo
provisioner. More detailed examples of how to use the provisioner are
available below this section.

* `cookbooks_path` (string or array) - A list of paths to where cookbooks
  are stored. By default this is "cookbooks", expecting a cookbooks folder
  relative to the Vagrantfile location.

* `data_bags_path` (string or array) - A path where data bags are stored. By
  default, no data bag path is set. Chef 12 or higher is required to use the
  array option. Chef 11 and lower only accept a string value.

* `environments_path` (string) - A path where environment definitions are
  located. By default, no environments folder is set.

* `nodes_path` (string or array) - A list of paths where node objects (in JSON format) are stored. By default, no
  nodes path is set.

* `environment` (string) - The environment you want the Chef run to be
  a part of. This requires Chef 11.6.0 or later, and that `environments_path`
  is set.

* `recipe_url` (string) - URL to an archive of cookbooks that Chef will download
  and use.

* `roles_path` (string or array) - A list of paths where roles are defined.
  By default this is empty. Multiple role directories are only supported by
  Chef 11.8.0 and later.

* `synced_folder_type` (string) - The type of synced folders to use when
  sharing the data required for the provisioner to work properly. By default
  this will use the default synced folder type. For example, you can set this
  to "nfs" to use NFS synced folders.

In addition to all the options listed above, the Chef Solo provisioner supports
the [common options for all Chef provisioners](/docs/provisioning/chef_common.html).

## Specifying a Run List

The easiest way to get started with the Chef Solo provisioner is to just
specify a [run list](https://docs.chef.io/nodes.html#about-run-lists). This looks like:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "chef_solo" do |chef|
    chef.add_recipe "apache"
  end
end
```

This causes Vagrant to run Chef Solo with the "apache" cookbook. The cookbooks
by default are looked for in the "cookbooks" directory relative to your
project root. The directory structure ends up looking like this:

```
$ tree
.
|-- Vagrantfile
|-- cookbooks
|   |-- apache
|       |-- recipes
|           |-- default.rb
```

The order of the calls to `add_recipe` will specify the order of the run list.
Earlier recipes added with `add_recipe` are run before later recipes added.

## Custom Cookbooks Path

Instead of using the default "cookbooks" directory, a custom cookbooks
path can also be set via the `cookbooks_path` configuration directive:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "chef_solo" do |chef|
    chef.cookbooks_path = "my_cookbooks"
  end
end
```

The path can be relative or absolute. If it is relative, it is relative
to the project root.

The configuration value can also be an array of paths:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "chef_solo" do |chef|
    chef.cookbooks_path = ["cookbooks", "my_cookbooks"]
  end
end
```

## Roles

Vagrant also supports provisioning with [Chef roles](https://docs.chef.io/roles.html).
This is done by specifying a path to a roles folder where roles are defined
and by adding roles to your run list:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "chef_solo" do |chef|
    chef.roles_path = "roles"
    chef.add_role("web")
  end
end
```

Just like the cookbooks path, the roles path is relative to the project
root if a relative path is given.

The configuration value can also be an array of paths on Chef 11.8.0 and newer.
On older Chef versions only the first path is used.

**Note:** The name of the role file must be the same as the role name.
For example the `web` role must be in the `roles_path` as web.json or web.rb.
This is required by Chef itself, and is not a limitation imposed by
Vagrant.

## Data Bags

[Data bags](https://docs.chef.io/data_bags.html) are also
supported by the Chef Solo provisioner. This is done by specifying
a path to your data bags directory:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "chef_solo" do |chef|
    chef.data_bags_path = "data_bags"
  end
end
```

## Custom JSON Data

Additional configuration data for Chef attributes can be passed in
to Chef Solo. This is done by setting the `json` property with a Ruby
hash (dictionary-like object), which is converted to JSON and passed
in to Chef:

```
Vagrant.configure("2") do |config|
  config.vm.provision "chef_solo" do |chef|
    # ...

    chef.json = {
      "apache" => {
        "listen_address" => "0.0.0.0"
      }
    }
  end
end
```

Hashes, arrays, etc. can be used with the JSON configuration object. Basically,
anything that can be turned cleanly into JSON works.

## Custom Node Name

You can specify a custom node name by setting the `node_name` property. This
is useful for cookbooks that may depend on this being set to some sort
of value. Example:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "chef_solo" do |chef|
    chef.node_name = "foo"
  end
end
```
