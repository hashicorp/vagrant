---
layout: "docs"
page_title: "CFEngine Provisioner"
sidebar_current: "provisioning-cfengine"
description: |-
  The Vagrant CFEngine provisioner allows you to provision the guest using
  CFEngine. It can set up both CFEngine policy servers and clients. You can
  configure both the policy server and the clients in a single multi-machine
  Vagrantfile.
---

# CFEngine Provisioner

**Provisioner name: `cfengine`**

The Vagrant CFEngine provisioner allows you to provision the guest using
[CFEngine](https://cfengine.com/). It can set up both CFEngine
policy servers and clients. You can configure both the policy server
and the clients in a single
[multi-machine `Vagrantfile`](/docs/multi-machine/).

<div class="alert alert-warning">
  <strong>Warning:</strong> If you are not familiar with CFEngine and Vagrant already,
  I recommend starting with the <a href="/docs/provisioning/shell.html">shell
  provisioner</a>. However, if you are comfortable with Vagrant
    already, Vagrant is the best way to learn CFEngine.
</div>

Let us look at some common examples first. See the bottom of this
document for a comprehensive list of options.

## Setting up a CFEngine server and client

The CFEngine provisioner automatically installs the latest
[CFEngine Community packages](https://cfengine.com/cfengine-linux-distros)
on the VM, then configures and starts CFEngine according to your
specification.

Configuring a VM as a CFEngine policy server is easy:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "cfengine" do |cf|
    cf.am_policy_hub = true
  end
end
```

The host will automatically be
[bootstrapped](https://cfengine.com/docs/3.5/manuals-architecture-networking.html#bootstrapping)
to itself to become a policy server.

If you already have a working CFEngine policy server, you can get a
CFEngine client installed and bootstrapped by specifying its IP
address:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "cfengine" do |cf|
    cf.policy_server_address = "10.0.2.15"
  end
end
```

## Copying files to the VM

If you have some policy or other files that you want to install by
default on a VM, you can use the `files_path` attribute:

```ruby
Vagrant.configure("2") do |config|
   config.vm.provision "cfengine" do |cf|
      cf.am_policy_hub = true
      cf.files_path = "cfengine_files"
    end
  end
```

Everything under `cfengine_files/` in the Vagrant project directory
will be recursively copied under `/var/cfengine/` in the VM, on top of
its default contents.

A common use case is to add your own files to
`/var/cfengine/masterfiles/` in the policy server. Assuming your extra
files are stored under `cfengine_files/masterfiles/`, the line shown
above will add them to the VM after CFEngine is installed, but before
it is bootstrapped.

## Modes of operation

The default mode of operation is `:bootstrap`, which results in
CFEngine being bootstrapped according to the information provided in
the `Vagrantfile`. You can also set `mode` to `:single_run`, which
will run `cf-agent` once on the host to execute the file specified in
the `run_file` parameter, but will not bootstrap it, so it will not be
executed periodically.

The recommended mode of operation is `:bootstrap`, as you get the full
benefits of CFEngine when you have it running periodically.

## Running a standalone file

If you want to run a standalone file, you can specify the `run_file`
parameter. The file will be copied to the VM and executed on its own
using `cf-agent`. Note that the file needs to be a standalone policy,
including its own
[`body common control`](https://cfengine.com/docs/3.5/reference-components.html#common-control).

The `run_file` parameter is mandatory if `mode` is set to
`:single_run`, but can also be specified when `mode` is set to
`:bootstrap` - in this case the file will be executed after the host
has been bootstrapped.

## Full Alphabetical List of Configuration Options

- `am_policy_hub` (boolean, default `false`) determines whether the VM will be
  configured as a CFEngine policy hub (automatically bootstrapped to
  its own IP address). You can combine it with `policy_server_address`
  if the VM has multiple network interfaces and you want to bootstrap
  to a specific one.
- `extra_agent_args` (string, default `nil`) can be used to pass
  additional arguments to `cf-agent` when it is executed. For example,
  you could use it to pass the `-I` or `-v` options to enable
  additional output from the agent.
- `classes` (array, default `nil`) can be used to define additional
  classes during `cf-agent` runs. These classes will be defined using
  the `-D` option to `cf-agent`.
- `deb_repo_file` (string, default
  `"/etc/apt/sources.list.d/cfengine-community.list"`) specifies the
  file in which the CFEngine repository information will be stored in
  Debian systems.
- `deb_repo_line` (string, default `"deb https://cfengine.com/pub/apt
  $(lsb_release -cs) main"`) specifies the repository to use for
  `.deb` packages.
- `files_path` (string, default `nil`) specifies a directory that will
  be copied to the VM on top of the default
  `/var/cfengine/` (the contents of `/var/cfengine/` will not
  be replaced, the files will added to it).
- `force_bootstrap` (boolean, default `false`) specifies whether
  CFEngine will be bootstrapped again even if the host has already
  been bootstrapped.
- `install` (boolean or `:force`, default `true`) specifies whether
  CFEngine will be installed on the VM if needed. If you set this
  parameter to `:force`, then CFEngine will be reinstalled even if
  it is already present on the machine.
- `mode` (`:bootstrap` or `:single_run`, default `:bootstrap`)
  specifies whether CFEngine will be bootstrapped so that it executes
  periodically, or will be run a single time. If `mode` is set to
  `:single_run` you have to set `run_file`.
- `policy_server_address` (string, no default) specifies the IP
  address of the policy server to which CFEngine will be
  bootstrapped. If `am_policy_hub` is set to `true`, this parameter
  defaults to the VM's IP address, but can still be set (for
  example, if the VM has more than one network interface).
- `repo_gpg_key_url` (string, default
  `"https://cfengine.com/pub/gpg.key"`) contains the URL to obtain the
  GPG key used to verify the packages obtained from the repository.
- `run_file` (string, default `nil`) can be used to specify a file
  inside the Vagrant project directory that will be copied to the VM
  and executed once using `cf-agent`. This parameter is mandatory if
  `mode` is set to `:single_run`, but can also be specified when
  `mode` is set to `:bootstrap` - in this case the file will be
  executed after the host has been bootstrapped.
- `upload_path` (string, default `"/tmp/vagrant-cfengine-file"`)
  specifies the file to which `run_file` (if specified) will be copied
  on the VM before being executed.
- `yum_repo_file` (string, default
  `"/etc/yum.repos.d/cfengine-community.repo"`) specifies the file in
  which the CFEngine repository information will be stored in RedHat
  systems.
- `yum_repo_url` (string, default `"https://cfengine.com/pub/yum/"`)
  specifies the URL of the repository to use for `.rpm` packages.
- `package_name` (string, default `"cfengine-community"`) specifies
  the name of the package used to install CFEngine.
