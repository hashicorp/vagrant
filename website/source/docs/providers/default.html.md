---
layout: "docs"
page_title: "Default Provider - Providers"
sidebar_current: "providers-default"
description: |-
  By default, VirtualBox is the default provider for Vagrant. VirtualBox is
  still the most accessible platform to use Vagrant: it is free, cross-platform,
  and has been supported by Vagrant for years. With VirtualBox as the default
  provider, it provides the lowest friction for new users to get started with
  Vagrant.
---

# Default Provider

By default, VirtualBox is the default provider for Vagrant. VirtualBox is
still the most accessible platform to use Vagrant: it is free, cross-platform,
and has been supported by Vagrant for years. With VirtualBox as the default
provider, it provides the lowest friction for new users to get started with
Vagrant.

However, you may find after using Vagrant for some time that you prefer
to use another provider as your default. In fact, this is quite common.
To make this experience better, Vagrant allows specifying the default
provider to use by setting the `VAGRANT_DEFAULT_PROVIDER` environmental
variable.

Just set `VAGRANT_DEFAULT_PROVIDER` to the provider you wish to be the
default. For example, if you use Vagrant with VMware Fusion, you can set
the environmental variable to `vmware_fusion` and it will be your default.
