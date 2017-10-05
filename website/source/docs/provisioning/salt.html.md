---
layout: "docs"
page_title: "Salt - Provisioning"
sidebar_current: "provisioning-salt"
description: |-
  The Vagrant Salt provisioner allows you to provision the guest using
  Salt states.
---
# Salt Provisioner

**Provisioner name: `salt`**

The Vagrant Salt provisioner allows you to provision the guest using
[Salt](http://saltstack.com/) states.

Salt states are  [YAML](https://en.wikipedia.org/wiki/YAML) documents
that describes the current state a machine should be in, e.g. what
packages should be installed, which services are running, and the
contents of arbitrary files.

_NOTE: The Salt provisioner is builtin to Vagrant. If the `vagrant-salt`
plugin is installed, it should be uninstalled to ensure expected behavior._

## Masterless Quickstart

What follows is a basic Vagrantfile that will get salt working
on a single minion, without a master:


```ruby
  Vagrant.configure("2") do |config|
    ## Choose your base box
    config.vm.box = "precise64"

    ## For masterless, mount your salt file root
    config.vm.synced_folder "salt/roots/", "/srv/salt/"

    ## Use all the defaults:
    config.vm.provision :salt do |salt|

      salt.masterless = true
      salt.minion_config = "salt/minion"
      salt.run_highstate = true

    end
  end
```

This sets up a shared folder for the salt root, and copies
the minion file over, then runs `state.highstate` on the
machine. Your minion file must contain the line
`file_client: local`  in order to work in a
masterless setup.

## Install Options

* `install_master`  (boolean) - Should vagrant install the salt-master
on this machine. Not supported on Windows guest machines.

* `no_minion`  (boolean) - Do not install the minion, default `false`. Not supported on Windows guest machines.

* `install_syndic`   (boolean) - Install the salt-syndic, default
`false`. Not supported on Windows guest machines.

* `install_type`  (stable | git | daily | testing) - Whether to install from a
distribution's stable package manager, git tree-ish, daily ppa, or testing repository. Not supported on Windows guest machines.

* `install_args` (string, default: "develop") - When performing a git install, you can specify a branch, tag, or any treeish. Not supported on Windows.

* `always_install`   (boolean) - Installs salt binaries even
 if they are already detected, default `false`

* `bootstrap_script` (string) - Path to your customized salt-bootstrap.sh script. Not supported on Windows guest machines.

* `bootstrap_options` (string) - Additional command-line options to
  pass to the bootstrap script.

* `version`  (string, default: "2017.7.1") - Version of minion to be installed. Only supported on Windows guest machines.

* `python_version`  (string, default: "2") - Major Python version of minion to be installed. Only valid for minion versions >= 2017.7.0. Only supported on Windows guest machines.

## Minion Options
These only make sense when `no_minion` is `false`.

* `minion_config`    (string, default: "salt/minion") - Path to
a custom salt minion config file.

* `minion_key`  (string, default: "salt/key/minion.key") - Path to your minion key

* `minion_id`  (string) - Unique identifier for minion. Used for masterless and preseeding keys.

* `minion_pub`  (string, default: "salt/key/minion.pub") - Path to your minion
public key

* `grains_config`  (string) - Path to a custom salt grains file. On Windows, the minion needs `ipc_mode: tcp` set otherwise it will [fail to communicate](https://github.com/saltstack/salt/issues/22796) with the master.

* `masterless`  (boolean) - Calls state.highstate in local mode. Uses `minion_id` and `pillar_data` when provided.

* `salt_call_args` (array) - An array of additional command line flag arguments to be passed to the `salt-call` command when provisioning with masterless.

## Master Options
These only make sense when `install_master` is `true`. Not supported on Windows guest machines.

* `master_config` (string, default: "salt/master")
  Path to a custom salt master config file.

* `master_key` (string, default: "salt/key/master.pem") - Path to your master key.

* `master_pub` (string, default: "salt/key/master.pub") - Path to your master public key.

* `seed_master`  (dictionary) - Upload keys to master, thereby
pre-seeding it before use. Example: `{minion_name:/path/to/key.pub}`

* `salt_args` (array) - An array of additional command line flag arguments to be passed to the `salt` command when provisioning with masterless.

## Execute States

Either of the following may be used to actually execute states
during provisioning.

* `run_highstate` - (boolean) Executes `state.highstate` on
vagrant up. Can be applied to any machine.

## Execute Runners

Either of the following may be used to actually execute runners
during provisioning.

* `run_overstate` - (boolean) Executes `state.over` on
vagrant up. Can be applied to the master only. This is superseded by
orchestrate. Not supported on Windows guest machines.

* `orchestrations` - (array of strings) Executes `state.orchestrate` on
vagrant up. Can be applied to the master only. This is superseded by
run_overstate. Not supported on Windows guest machines.

## Output Control

These may be used to control the output of state execution:

* `colorize` (boolean) - If true, output is colorized. Defaults to false.

* `log_level` (string) - The verbosity of the outputs. Defaults to "debug".
  Can be one of "all", "garbage", "trace", "debug", "info", or
  "warning". Requires `verbose` to be set to "true".

* `verbose` (boolean) - The verbosity of the outputs. Defaults to "false".
  Must be true for log_level taking effect and the output of the salt-commands being displayed.

## Pillar Data

You can export pillar data for use during provisioning by using the ``pillar``
command. Each call will merge the data so you can safely call it multiple
times. The data passed in should only be hashes and lists. Here is an example::

```ruby
      config.vm.provision :salt do |salt|

        # Export hostnames for webserver config
        salt.pillar({
          "hostnames" => {
            "www" => "www.example.com",
            "intranet" => "intranet.example.com"
          }
        })

        # Export database credentials
        salt.pillar({
          "database" => {
            "user" => "jdoe",
            "password" => "topsecret"
          }
        })

        salt.run_highstate = true

      end
```

## Preseeding Keys

Preseeding keys is the recommended way to handle provisioning
using a master.
On a machine with salt installed, run
`salt-key --gen-keys=[minion_id]` to generate the necessary
.pub and .pem files

For a an example of a more advanced setup, look at the original
[plugin](https://github.com/saltstack/salty-vagrant/tree/develop/example).
