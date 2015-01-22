---
page_title: "Salt - Provisioning"
sidebar_current: "provisioning-salt"
---
# Salt Provisioner

**Provisioner name: `salt`**

The salt Provisioner allows you to provision the guest using
[Salt](http://saltstack.com/) states.

Salt states are  [YAML](http://en.wikipedia.org/wiki/YAML) documents
that describes the current state a machine should be in, e.g. what
packages should be installed, which services are running, and the
contents of arbitrary files.

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
on this machine. Not supported on Windows.

* `no_minion`  (boolean) - Don't install the minion, default `false`

* `install_syndic`   (boolean) - Install the salt-syndic, default
`false`. Not supported on Windows.

* `install_type`  (stable | git | daily | testing) - Whether to install from a
distribution's stable package manager, git tree-ish, daily ppa, or testing repository.
Not supported on Windows.

* `install_args` (develop) - When performing a git install,
you can specify a branch, tag, or any treeish. Not supported on Windows.

* `always_install`   (boolean) - Installs salt binaries even
 if they are already detected, default `false`


## Minion Options
These only make sense when `no_minion` is `false`.

* `minion_config`    (string, default: "salt/minion") - Path to
a custom salt minion config file.

* `minion_key`  (string) - Path to your minion key

* `minion_pub`  (salt/key/minion.pub) - Path to your minion
public key

* `grains_config`  (string) - Path to a custom salt grains file.

## Master Options
These only make sense when `install_master` is `true`.

* `master_config` (string, default: "salt/minion")
  Path to a custom salt master config file

* `master_key` (salt/key/master.pem) - Path to your master key

* `master_pub` (salt/key/master.pub) - Path to your master public key

* `seed_master`  (dictionary) - Upload keys to master, thereby
pre-seeding it before use. Example: `{minion_name:/path/to/key.pub}`

## Execute States

Either of the following may be used to actually execute states
during provisioning.

* `run_highstate` - (boolean) Executes `state.highstate` on
vagrant up. Can be applied to any machine.
* `run_overstate` - (boolean) Executes `state.over` on
vagrant up. Can be applied to the master only.

## Output Control

These may be used to control the output of state execution:

* `colorize` (boolean) - If true, output is colorized. Defaults to false.

* `log_level` (string) - The verbosity of the outputs. Defaults to "debug".
  Can be one of "all", "garbage", "trace", "debug", "info", or
  "warning".

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

Preseeding keys is the recommended way to handle provisiong
using a master.
On a machine with salt installed, run
`salt-key --gen-keys=[minion_id]` to generate the necessary
.pub and .pem files

For a an example of a more advanced setup, look at the original
[plugin](https://github.com/saltstack/salty-vagrant/tree/develop/example).





