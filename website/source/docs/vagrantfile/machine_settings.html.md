---
layout: "docs"
page_title: "config.vm - Vagrantfile"
sidebar_current: "vagrantfile-machine"
description: |-
  The settings within "config.vm" modify the configuration of the
  machine that Vagrant manages.
---

# Machine Settings

**Config namespace: `config.vm`**

The settings within `config.vm` modify the configuration of the
machine that Vagrant manages.

## Available Settings

* `config.vm.base_mac` (string) - The MAC address to be assigned to the default
NAT interface on the guest. _Support for this option is provider dependent._

* `config.vm.base_address` (string) - The IP address to be assigned to the default
NAT interface on the guest. _Support for this option is provider dependent._

* `config.vm.boot_timeout` (integer) - The time in seconds that Vagrant will wait
for the machine to boot and be accessible. By default this is 300 seconds.

* `config.vm.box` (string) - This configures what [box](/docs/boxes.html) the
machine will be brought up against. The value here should be the name
of an installed box or a shorthand name of a box in
[HashiCorp's Vagrant Cloud](/docs/vagrant-cloud).

* `config.vm.box_check_update` (boolean) - If true, Vagrant will check for updates to
the configured box on every `vagrant up`. If an update is found, Vagrant
will tell the user. By default this is true. Updates will only be checked
for boxes that properly support updates (boxes from
[HashiCorp's Vagrant Cloud](/docs/vagrant-cloud)
or some other versioned box).

* `config.vm.box_download_checksum` (string) - The checksum of the box specified by
`config.vm.box_url`. If not specified, no checksum comparison will be done.
If specified, Vagrant will compare the checksum of the downloaded box to
this value and error if they do not match. Checksum checking is only done
when Vagrant must download the box. If this is specified, then
`config.vm.box_download_checksum_type` must also be specified.

* `config.vm.box_download_checksum_type` (string) - The type of checksum specified
by `config.vm.box_download_checksum` (if any). Supported values are
currently "md5", "sha1", and "sha256".

* `config.vm.box_download_client_cert` (string) - Path to a client certificate to
use when downloading the box, if it is necessary. By default, no client
certificate is used to download the box.

* `config.vm.box_download_ca_cert` (string) - Path to a CA cert bundle to use when
downloading a box directly. By default, Vagrant will use the Mozilla CA cert
bundle.

* `config.vm.box_download_ca_path` (string) - Path to a directory containing
CA certificates for downloading a box directly. By default, Vagrant will
use the Mozilla CA cert bundle.

* `config.vm.box_download_insecure` (boolean) - If true, then SSL certificates
from the server will not be verified. By default, if the URL is an HTTPS
URL, then SSL certs will be verified.

* `config.vm.box_download_location_trusted` (boolean) - If true, then all HTTP redirects will be
treated as trusted. That means credentials used for initial URL will be used for
all subsequent redirects. By default, redirect locations are untrusted so credentials
(if specified) used only for initial HTTP request.

* `config.vm.box_url` (string, array of strings) - The URL that the configured box can be found at.
If `config.vm.box` is a shorthand to a box in [HashiCorp's Vagrant Cloud](/docs/vagrant-cloud)
then this value does not need to be specified. Otherwise, it should
point to the proper place where the box can be found if it is not
installed. This can also be an array of multiple URLs. The URLs will be tried in
order.

    Note that any client certificates, insecure download settings, and
    so on will apply to all URLs in this list. The URLs can also be local files
    by using the `file://` scheme. For example: "file:///tmp/test.box".

* `config.vm.box_version` (string) - The version of the box to use. This defaults to
">= 0" (the latest version available). This can contain an arbitrary list
of constraints, separated by commas, such as: `>= 1.0, < 1.5`. When constraints
are given, Vagrant will use the latest available box satisfying these
constraints.

* `config.vm.communicator` (string) - The communicator type to use to connect to the
guest box. By default this is `"ssh"`, but should be changed to `"winrm"` for
Windows guests.

* `config.vm.graceful_halt_timeout` (integer) - The time in seconds that Vagrant will
wait for the machine to gracefully halt when `vagrant halt` is called.
Defaults to 60 seconds.

* `config.vm.guest` (string, symbol) - The guest OS that will be running within this
machine. This defaults to `:linux`, and Vagrant will auto-detect the
proper distro. However, this should be changed to `:windows` for Windows guests.
Vagrant needs to know this information to perform some guest OS-specific things
such as mounting folders and configuring networks.

* `config.vm.hostname` (string) - The hostname the machine should have. Defaults
to nil. If nil, Vagrant will not manage the hostname. If set to a string,
the hostname will be set on boot. If set, Vagrant will update `/etc/hosts`
on the guest with the configured hostname.

* `config.vm.ignore_box_vagrantfile` (boolean) - If true, Vagrant will not load the the
settings found inside a boxes Vagrantfile, if present. Defaults to `false`.

* `config.vm.network` - Configures [networks](/docs/networking/) on
the machine. Please see the networking page for more information.

* `config.vm.post_up_message` (string) - A message to show after `vagrant up`. This
will be shown to the user and is useful for containing instructions
such as how to access various components of the development environment.

* `config.vm.provider` - Configures [provider-specific configuration](/docs/providers/configuration.html),
which is used to modify settings which are specific to a certain
[provider](/docs/providers/). If the provider you are configuring
does not exist or is not setup on the system of the person who runs
`vagrant up`, Vagrant will ignore this configuration block. This allows
a Vagrantfile that is configured for many providers to be shared among
a group of people who may not have all the same providers installed.

* `config.vm.provision` - Configures [provisioners](/docs/provisioning/)
on the machine, so that software can be automatically installed and configured
when the machine is created. Please see the page on provisioners for more
information on how this setting works.

* `config.vm.synced_folder` - Configures [synced folders](/docs/synced-folders/)
on the machine, so that folders on your host machine can be synced to
and from the guest machine. Please see the page on synced folders for
more information on how this setting works.

* `config.vm.usable_port_range` (range) - A range of ports Vagrant can use for
handling port collisions and such. Defaults to `2200..2250`.
