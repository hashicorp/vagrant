---
layout: "docs"
page_title: "Basic Usage - Synced Folders"
sidebar_current: "syncedfolder-basic"
description: |-
  Synced folders are configured within your Vagrantfile using the
  "config.vm.synced_folder" method.
---

# Basic Usage

## Configuration

Synced folders are configured within your Vagrantfile using the
`config.vm.synced_folder` method. Usage of the configuration directive
is very simple:

```ruby
Vagrant.configure("2") do |config|
  # other config here

  config.vm.synced_folder "src/", "/srv/website"
end
```

The first parameter is a path to a directory on the host machine. If
the path is relative, it is relative to the project root. The second
parameter must be an absolute path of where to share the folder within
the guest machine. This folder will be created (recursively, if it must)
if it does not exist.

## Options

You may also specify additional optional parameters when configuring
synced folders. These options are listed below. More detailed examples of using
some of these options are shown below this section, note the owner/group example
supplies two additional options separated by commas.

In addition to these options, the specific synced folder type might
allow more options. See the documentation for your specific synced folder
type for more details. The built-in synced folder types are documented
in other pages available in the navigation for these docs.

* `create` (boolean) - If true, the host path will be created if it
  does not exist. Defaults to false.

* `disabled` (boolean) - If true, this synced folder will be disabled and
  will not be setup. This can be used to disable a previously defined synced
  folder or to conditionally disable a definition based on some external
  factor.

* `group` (string) - The group that will own the synced folder. By default
  this will be the SSH user. Some synced folder types do not support
  modifying the group.

* `mount_options` (array) - A list of additional mount options to pass
 to the `mount` command.

* `owner` (string) - The user who should be the owner of this synced folder.
  By default this will be the SSH user. Some synced folder types do not
  support modifying the owner.

* `type` (string) - The type of synced folder. If this is not specified,
  Vagrant will automatically choose the best synced folder option for your
  environment. Otherwise, you can specify a specific type such as "nfs".

* `id` (string) - The name for the mount point of this synced folder in the
  guest machine. This shows up when you run `mount` in the guest machine.

## Enabling

Synced folders are automatically setup during `vagrant up` and
`vagrant reload`.

## Disabling

Synced folders can be disabled by adding the `disabled` option to
any definition:

```ruby
Vagrant.configure("2") do |config|
  config.vm.synced_folder "src/", "/srv/website", disabled: true
end
```

Disabling the default `/vagrant` share can be done as follows:

```ruby
config.vm.synced_folder ".", "/vagrant", disabled: true
```

## Modifying the Owner/Group

By default, Vagrant mounts the synced folders with the owner/group set
to the SSH user. Sometimes it is preferable to mount folders with a different
owner and group. It is possible to set these options:

```ruby
config.vm.synced_folder "src/", "/srv/website",
  owner: "root", group: "root"
```

_NOTE: Owner and group IDs defined within `mount_options` will have precedence
over the `owner` and `group` options._

For example, given the following configuration:

```ruby
config.vm.synced_folder ".", "/vagrant", owner: "vagrant",
  group: "vagrant", mount_options: ["uid=1234", "gid=1234"]
```

the mounted synced folder will be owned by the user with ID `1234` and the
group with ID `1234`. The `owner` and `group` options will be ignored.

## Symbolic Links

Support for symbolic links across synced folder implementations and
host/guest combinations is not consistent. Vagrant does its best to
make sure symbolic links work by configuring various hypervisors (such
as VirtualBox), but some host/guest combinations still do not work
properly. This can affect some development environments that rely on
symbolic links.

The recommendation is to make sure to test symbolic links on all the
host/guest combinations you sync folders on if this is important to you.
