---
layout: "docs"
page_title: "Configuration - Providers"
sidebar_current: "providers-configuration"
description: |-
  While well-behaved Vagrant providers should work with any Vagrantfile with
  sane defaults, providers generally expose unique configuration options so that
  you can get the most out of each provider.  
---

# Configuration

While well-behaved Vagrant providers should work with any Vagrantfile with sane
defaults, providers generally expose unique configuration
options so that you can get the most out of each provider.

This provider-specific configuration is done within the Vagrantfile
in a way that is portable, easy to use, and easy to understand.

## Portability

An important fact is that even if you configure other providers within
a Vagrantfile, the Vagrantfile remains portable even to individuals who
do not necessarily have that provider installed.

For example, if you configure VMware Fusion and send it to an individual
who does not have the VMware Fusion provider, Vagrant will silently ignore
that part of the configuration.

## Provider Configuration

Configuring a specific provider looks like this:

```ruby
Vagrant.configure("2") do |config|
  # ...

  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
  end
end
```

Multiple `config.vm.provider` blocks can exist to configure multiple
providers.

The configuration format should look very similar to how provisioners
are configured. The `config.vm.provider` takes a single parameter: the
name of the provider being configured. Then, an inner block with custom
configuration options is exposed that can be used to configure that
provider.

This inner configuration differs among providers, so please read the
documentation for your provider of choice to see available configuration
options.

Remember, some providers do not require any provider-specific configuration
and work directly out of the box. Provider-specific configuration is meant
as a way to expose more options to get the most of the provider of your
choice. It is not meant as a roadblock to running against a specific provider.

## Overriding Configuration

Providers can also override non-provider specific configuration, such
as `config.vm.box` and any other Vagrant configuration. This is done by
specifying a second argument to `config.vm.provider`. This argument is
just like the normal `config`, so set any settings you want, and they will
be overridden only for that provider.

Example:

```
Vagrant.configure("2") do |config|
  config.vm.box = "precise64"

  config.vm.provider "vmware_fusion" do |v, override|
    override.vm.box = "precise64_fusion"
  end
end
```

In the above case, Vagrant will use the "precise64" box by default, but
will use "precise64_fusion" if the VMware Fusion provider is used.

<div class="alert alert-info">
  <strong>The Vagrant Way:</strong> The proper "Vagrant way" is to
  avoid any provider-specific overrides if possible by making boxes
  for multiple providers that are as identical as possible, since box
  names can map to multiple providers. However, this is not always possible,
  and in those cases, overrides are available.
</div>
