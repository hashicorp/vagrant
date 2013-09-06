---
page_title: "Basic Usage - Providers"
sidebar_current: "providers-basic-usage"
---

# Basic Provider Usage

## Boxes

Boxes are all provider-specific. A box for VirtualBox is incompatible with
the VMware Fusion provider, or any other provider. A box must be installed
for each provider, and can share the same name as other boxes as long
as the providers differ. So you can have both a VirtualBox and VMware Fusion
"precise64" box.

Installing boxes hasn't changed at all:

```
$ vagrant box add \
  precise64 http://files.vagrantup.com/precise64.box
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

Once a provider is installed, it is used by calling `vagrant up` with the `--provider` flag,
specifying the provider you want to back the machine. No other configuration
is necessary! What this looks like:

```
$ vagrant up --provider=vmware_fusion
```

If the provider is well-behaved then everything should just work. Of course,
each provider typically exposes custom configuration options to fine tune
and control that provider, but defaults should work great to get started.

From this point forward, you can use all the other commands without
specifying a `--provider`; Vagrant is able to figure it out on its own.
Specifically, once you run `vagrant up --provider`, Vagrant is able to see
what provider is backing an existing machine, so commands such as `destroy`,
`suspend`, etc. do not need to be told what provider to use.

<div class="alert alert-info">
	<h3>Limitations</h3>
	<p>
		Vagrant currently restricts you to bringing up one provider per machine.
		If you have a multi-machine environment, you can bring up one machine
		backed by VirtualBox and another backed by VMware Fusion, for example, but you
		can't back the <em>same machine</em> with both VirtualBox and
		VMware Fusion.
	</p>

	<p>
		This is a limitation that will be removed in a future version of
		Vagrant.
	</p>
</div>
