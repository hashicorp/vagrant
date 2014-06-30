---
page_title: "Common Chef Options - Provisioning"
sidebar_current: "provisioning-chefcommon"
---

# Shared Chef Options

This page documents the list of available options that are available in
both the
[Chef solo](/v2/provisioning/chef_solo.html)
and
[Chef client](/v2/provisioning/chef_client.html)
provisioners.

* `arguments` (string) - A list of additional arguments to pass on the
  command-line to Chef. Since these are passed in a shell-like environment,
  be sure to properly quote and escape characters if necessary. By default,
  no additional arguments are sent.

* `attempts` (int) - The number of times Chef will be run if an error occurs.
  This defaults to 1. This can be increased to a higher number if your Chef
  runs take multiple runs to reach convergence.

* `binary_path` (string) - The path to the directory of the Chef executable
  binaries. By default, Vagrant looks for the proper Chef binary on the PATH.

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
