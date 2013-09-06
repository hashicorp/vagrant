---
page_title: "config.vm - Vagrantfile"
sidebar_current: "vagrantfile-machine"
---

# Machine Settings

**Config namespace: `config.vm`**

The settings within `config.vm` modify the configuration of the
machine that Vagrant manages.

## Available Settings

`config.vm.boot_timeout` - The time in seconds that Vagrant will wait
for the machine to boot and be accessible. By default this is 300 seconds.

<hr>

`config.vm.box` - This configures what [box](/v2/boxes/index.html) the
machine will be brought up against. The value here should match one of
the installed boxes on the system.

<hr>

`config.vm.box_url` - The URL that the configured box can be found at.
If the box is not installed on the system, it will be retrieved from this
URL when `vagrant up` is run.

<hr>

`config.vm.graceful_halt_timeout` - The time in seconds that Vagrant will
wait for the machine to gracefully halt when `vagrant halt` is called.
Defaults to 300 seconds.

<hr>

`config.vm.guest` - The guest OS that will be running within this
machine. This defaults to `:linux`, and Vagrant will auto-detect the
proper distro. Vagrant needs to know this information to perform some
guest OS-specific things such as mounting folders and configuring
networks.

<hr>

`config.vm.hostname` - The hostname the machine should have. Defaults
to nil. If nil, Vagrant won't manage the hostname. If set to a string,
the hostname will be set on boot.

<hr>

`config.vm.network` - Configures [networks](/v2/networking/index.html) on
the machine. Please see the networking page for more information.

<hr>

`config.vm.provider` - Configures [provider-specific configuration](/v2/providers/configuration.html),
which is used to modify settings which are specific to a certain
[provider](/v2/providers/index.html). If the provider you're configuring
doesn't exist or is not setup on the system of the person who runs
`vagrant up`, Vagrant will ignore this configuration block. This allows
a Vagrantfile that is configured for many providers to be shared among
a group of people who may not have all the same providers installed.

<hr>

`config.vm.provision` - Configures [provisioners](/v2/provisioning/index.html)
on the machine, so that software can be automatically installed and configured
when the machine is created. Please see the page on provisioners for more
information on how this setting works.

<hr>

`config.vm.synced_folder` - Configures [synced folders](/v2/synced-folders/index.html)
on the machine, so that folders on your host machine can be synced to
and from the guest machine. Please see the page on synced folders for
more information on how this setting works.

<hr>

`config.vm.usable_port_range` - A range of ports Vagrant can use for
handling port collisions and such. Defaults to `2200..2250`.

<hr>
