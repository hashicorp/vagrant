---
layout: "docs"
page_title: "Basic Usage - Networking"
sidebar_current: "networking-basic"
description: |-
  Vagrant offers multiple options for how you are able to connect your
  guest machines to the network, but there is a standard usage pattern as
  well as some points common to all network configurations that
  are important to know.
---

# Basic Usage of Networking

Vagrant offers multiple options for how you are able to connect your
guest machines to the network, but there is a standard usage pattern as
well as some points common to all network configurations that
are important to know.

## Configuration

All networks are configured within your [Vagrantfile](/docs/vagrantfile/)
using the `config.vm.network` method call. For example, the Vagrantfile
below defines some port forwarding:

```ruby
Vagrant.configure("2") do |config|
  # ...
  config.vm.network "forwarded_port", guest: 80, host: 8080
end
```

Every network type has an identifier such as `"forwarded_port"` in the above
example. Following this is a set of configuration arguments that can differ
for each network type. In the case of forwarded ports, two numeric arguments
are expected: the port on the guest followed by the port on the host that
the guest port can be accessed by.

## Multiple Networks

Multiple networks can be defined by having multiple `config.vm.network`
calls within the Vagrantfile. The exact meaning of this can differ for
each [provider](/docs/providers/), but in general the order specifies
the order in which the networks are enabled.

## Enabling Networks

Networks are automatically configured and enabled after they've been defined
in the Vagrantfile as part of the `vagrant up` or `vagrant reload` process.
