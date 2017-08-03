---
layout: "docs"
page_title: "Common Chef Options - Provisioning"
sidebar_current: "provisioning-chefcommon"
description: |-
  The following options are available to all Vagrant Chef provisioners. Many of
  these options are for advanced users only and should not be used unless you
  understand their purpose.
---

# Shared Chef Options

## All Chef Provisioners

The following options are available to all Vagrant Chef provisioners. Many of
these options are for advanced users only and should not be used unless you
understand their purpose.

- `binary_path` (string) - The path to Chef's `bin/` directory on the guest
  machine.

- `binary_env` (string) - Arbitrary environment variables to set before running
  the Chef provisioner command. This should be of the format `KEY=value` as a
  string.

- `install` (boolean, string) - Install Chef on the system if it does not exist.
  The default value is "true", which will use the official Omnibus installer
  from Chef. This is a trinary attribute (it can have three values):

    - `true` (boolean) - install Chef
    - `false` (boolean) - do not install Chef
    - `"force"` (string) - install Chef, even if it is already installed at the
      proper version on the guest

- `installer_download_path` (string) - The path where the Chef installer will be
  downloaded to. This option is only honored if the `install` attribute is
  `true` or `"force"`. The default value is to use the path provided by Chef's
  Omnibus installer, which varies between releases. This value has no effect on
  Windows because Chef's omnibus installer lacks the option on Windows.

- `log_level` (string) - The Chef log level. See the Chef docs for acceptable
  values.

- `product` (string) - The name of the Chef product to install. The default
  value is "chef", which corresponds to the Chef Client. You can also specify
  "chefdk", which will install the Chef Development Kit. At the time of this
  writing, the ChefDK is only available through the "current" channel, so you
  will need to update that value as well.

- `channel` (string) - The release channel from which to pull the Chef Client
  or the Chef Development Kit. The default value is `"stable"` which will pull
  the latest stable version of the Chef Client. For newer versions, or if you
  wish to install the Chef Development Kit, you may need to change the channel
  to "current". Because Chef Software floats the versions that are contained in
  the channel, they may change and Vagrant is unable to detect this.

- `version` (string) - The version of Chef to install on the guest. If Chef is
  already installed on the system, the installed version is compared with the
  requested version. If they match, no action is taken. If they do not match,
  the value specified in this attribute will be installed in favor of the
  existing version (a message will be displayed).
  You can also specify "latest" (default), which will install the latest
  version of Chef on the system. In this case, Chef will use whatever
  version is on the system. To force the newest version of Chef to be
  installed on every provision, set the [`install`](#install) option to "force".

- `omnibus_url` (string) - Location of Omnibus installation scripts.
  This URL specifies the location of install.sh/install.ps1 for
  Linux/Unix and Windows respectively.
  It defaults to https://omnitruck.chef.io. The full URL is in this case:

   - Linux/Unix: https://omnitruck.chef.io/install.sh
   - Windows: https://omnitruck.chef.io/install.ps1

  If you want to have https://example.com/install.sh as Omnibus script
  for your Linux/Unix installations, you should set this option to
  https://example.com

## Runner Chef Provisioners

The following options are available to any of the Chef "runner" provisioners
which include [Chef Solo](/docs/provisioning/chef_solo.html), [Chef Zero](/docs/provisioning/chef_zero.html), and [Chef Client](/docs/provisioning/chef_client.html).

* `arguments` (string) - A list of additional arguments to pass on the
  command-line to Chef. Since these are passed in a shell-like environment,
  be sure to properly quote and escape characters if necessary. By default,
  no additional arguments are sent.

* `attempts` (int) - The number of times Chef will be run if an error occurs.
  This defaults to 1. This can be increased to a higher number if your Chef
  runs take multiple runs to reach convergence.

* `custom_config_path` (string) - A path to a custom Chef configuration local
  on your machine that will be used as the Chef configuration. This Chef
  configuration will be loaded _after_ the Chef configuration that Vagrant
  generates, allowing you to override anything that Vagrant does. This is
  also a great way to use new Chef features that may not be supported fully
  by Vagrant's abstractions yet.

* `encrypted_data_bag_secret_key_path` (string) - The path to the secret key
  file to decrypt encrypted data bags. By default, this is not set.

* `environment` (string) - The environment you want the Chef run to be
  a part of.

* `formatter` (string) - The formatter to use for output from Chef.

* `http_proxy`, `http_proxy_user`, `http_proxy_pass`, `no_proxy` (string) - Settings
  to configure HTTP and HTTPS proxies to use from Chef. These settings are
  also available with `http` replaced with `https` to configure HTTPS proxies.

* `json` (hash) - Custom node attributes to pass into the Chef run.

* `log_level` (string) - The log level for Chef output. This defaults to
  "info".

* `node_name` (string) - The node name for the Chef Client. By default this
  will be your hostname.

* `provisioning_path` (string) - The path on the remote machine where Vagrant
  will store all necessary files for provisioning such as cookbooks, configurations,
  etc. This path must be world writable. By default this is
  `/tmp/vagrant-chef-#` where "#" is replaced by a unique counter.

* `run_list` (array) - The run list that will be executed on the node.

* `file_cache_path` and `file_backup_path` (string) - Paths on the remote
  machine where files will be cached and backed up. It is useful sometimes
  to configure this to a synced folder address so that this can be shared
  across many Vagrant runs.

* `verbose_logging` (boolean) - Whether or not to enable the Chef
  `verbose_logging` option. By default this is false.

* `enable_reporting` (boolean) - Whether or not to enable the Chef
  `enable_reporting` option. By default this is true.
