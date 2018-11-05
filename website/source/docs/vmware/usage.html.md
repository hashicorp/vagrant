---
layout: "docs"
page_title: "Usage - VMware Provider"
sidebar_current: "providers-vmware-usage"
description: |-
  The Vagrant VMware providers are used just like any other provider. Please
  read the general basic usage page for providers.
---

# Usage

The Vagrant VMware provider is used just like any other provider. Please
read the general [basic usage](/docs/providers/basic_usage.html) page for
providers.

The value to use for the `--provider` flag is `vmware_desktop`. For compatibility
with older versions of the plugin, `vmware_fusion` can be used for VMware
Fusion, and `vmware_workstation` for VMware Workstation.

The Vagrant VMware provider does not support parallel execution at this time.
Specifying the `--parallel` option will have no effect.

To get started, create a new `Vagrantfile` that points to a VMware box:

```ruby
# vagrant init hashicorp/precise64
Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/precise64"
end
```

Then run:

```shell
$ vagrant up --provider vmware_desktop
```

This will download and bring up a new VMware Fusion/Workstation virtual machine
in Vagrant.
