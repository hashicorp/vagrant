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

`config.vm.box` - This configures what [box](/v2/boxes.html) the
machine will be brought up against. The value here should be the name
of an installed box or a shorthand name of a box in
[Vagrant Cloud](#).

<hr>

`config.vm.box_check_update` - If true, Vagrant will check for updates to
the configured box on every `vagrant up`. If an update is found, Vagrant
will tell the user. By default this is true. Updates will only be checked
for boxes that properly support updates (boxes from
[Vagrant Cloud](#)
or some other versioned box).

<hr>

`config.vm.box_download_checksum` - The checksum of the box specified by
`config.vm.box_url`. If not specified, no checksum comparison will be done.
If specified, Vagrant will compare the checksum of the downloaded box to
this value and error if they do not match. Checksum checking is only done
when Vagrant must download the box.

If this is specified, then `config.vm.box_download_checksum_type` must
also be specified.

<hr>

`config.vm.box_download_checksum_type` - The type of checksum specified
by `config.vm.box_download_checksum` (if any). Supported values are
currently "md5", "sha1", and "sha256".

<hr>

`config.vm.box_download_client_cert` - Path to a client certificate to
use when downloading the box, if it is necessary. By default, no client
certificate is used to download the box.

<hr>

`config.vm.box_download_insecure` - If true, then SSL certificates
from the server will not be verified. By default, if the URL is an HTTPS
URL, then SSL certs will be verified.

<hr>

`config.vm.box_url` - The URL that the configured box can be found at.
If `config.vm.box` is a shorthand to a box in [Vagrant Cloud](#)
then this value doesn't need to be specified. Otherwise, it should
point to the proper place where the box can be found if it isn't
installed.

This can also be an array of multiple URLs. The URLs will be tried in
order. Note that any client certificates, insecure download settings, and
so on will apply to all URLs in this list.

<hr>

`config.vm.box_version` - The version of the box to use. This defaults to
">= 0" (the latest version available). This can contain an arbitrary list
of constraints, separated by commas, such as: `>= 1.0, < 1.5`. When constraints
are given, Vagrant will use the latest available box satisfying these
constraints.

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
