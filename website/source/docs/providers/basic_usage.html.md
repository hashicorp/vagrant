---
layout: "docs"
page_title: "Basic Usage - Providers"
sidebar_current: "providers-basic-usage"
description: |-
  Vagrant boxes are all provider-specific. A box for VirtualBox is incompatible
  with the VMware Fusion provider, or any other provider. A box must be
  installed for each provider, and can share the same name as other boxes as
  long as the providers differ. So you can have both a VirtualBox and VMware
  Fusion "precise64" box.
---

# Basic Provider Usage

## Boxes

Vagrant boxes are all provider-specific. A box for VirtualBox is incompatible
with the VMware Fusion provider, or any other provider. A box must be installed
for each provider, and can share the same name as other boxes as long
as the providers differ. So you can have both a VirtualBox and VMware Fusion
"precise64" box.

Installing boxes has not changed at all:

```
$ vagrant box add \
  precise64 https://files.hashicorp.com/precise64.box
```

Vagrant now automatically detects what provider a box is for. This is
visible when listing boxes. Vagrant puts the provider in parentheses next
to the name, as can be seen below.

```
$ vagrant box list
precise64 (virtualbox)
precise64 (vmware_fusion)
```

## Vagrant Up

Once a provider is installed, you can use it by calling `vagrant up`
with the `--provider` flag. This will force Vagrant to use that specific
provider. No other configuration is necessary!

In normal day-to-day usage, the `--provider` flag is not necessary
since Vagrant can usually pick the right provider for you. More details
on how it does this is below.

```
$ vagrant up --provider=vmware_fusion
```

If you specified a `--provider` flag, you only need to do this for the
`up` command. Once a machine is up and running, Vagrant is able to
see what provider is backing a running machine, so commands such as
`destroy`, `suspend`, etc. do not need to be told what provider to use.

<div class="alert alert-info">
  Vagrant currently restricts you to bringing up one provider per machine.
  If you have a multi-machine environment, you can bring up one machine
  backed by VirtualBox and another backed by VMware Fusion, for example, but you
  cannot back the <em>same machine</em> with both VirtualBox and
  VMware Fusion. This is a limitation that will be removed in a future
  version of Vagrant.
</div>

## Default Provider

As mentioned earlier, you typically do not need to specify `--provider`
_ever_. Vagrant is smart enough about being able to detect the provider
you want for a given environment.

Vagrant attempts to find the default provider in the following order:

  1. The `--provider` flag on a `vagrant up` is chosen above all else, if
     it is present.

  2. If the `VAGRANT_DEFAULT_PROVIDER` environmental variable is set,
     it takes next priority and will be the provider chosen.

  3. Vagrant will go through all of the `config.vm.provider` calls in the
     Vagrantfile and try each in order. It will choose the first provider
     that is usable. For example, if you configure Hyper-V, it will never
     be chosen on Mac this way. It must be both configured and usable.

  4. Vagrant will go through all installed provider plugins (including the
     ones that come with Vagrant), and find the first plugin that reports
     it is usable. There is a priority system here: systems that are known
     better have a higher priority than systems that are worse. For example,
     if you have the VMware provider installed, it will always take priority
     over VirtualBox.

  5. If Vagrant still has not found any usable providers, it will error.

Using this method, there are very few cases that Vagrant does not find the
correct provider for you. This also allows each
[Vagrantfile](/docs/vagrantfile/) to define what providers
the development environment is made for by ordering provider configurations.

A trick is to use `config.vm.provider` with no configuration at the top of
your Vagrantfile to define the order of providers you prefer to support:

```ruby
Vagrant.configure("2") do |config|
  # ... other config up here

  # Prefer VMware Fusion before VirtualBox
  config.vm.provider "vmware_fusion"
  config.vm.provider "virtualbox"
end
```
