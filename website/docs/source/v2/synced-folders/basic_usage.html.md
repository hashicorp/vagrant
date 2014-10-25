---
page_title: "Basic Usage - Synced Folders"
sidebar_current: "syncedfolder-basic"
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
if it doesn't exist.

## Options

As an optional third parameter to configuring synced folders, you may specify
some options. These options are listed below. More detailed examples of using
some of these options are shown below this section.

In addition to these options, the specific synced folder type might
allow more options. See the documentation for your specific synced folder
type for more details. The built-in synced folder types are documented
in other pages available in the navigation for these docs.

* `create` (boolean) - If true, the host path will be created if it
  does not exist. Defaults to false.

* `disabled` (boolean) - If true, this synced folder will be disabled and
  won't be setup. This can be used to disable a previously defined synced
  folder or to conditionally disable a definition based on some external
  factor.

* `group` (string) - The group that will own the synced folder. By default
  this will be the SSH user. Some synced folder types don't support
  modifying the group.

* `mount_options` (array) - A list of additional mount options to pass
 to the `mount` command.

* `owner` (string) - The user who should be the owner of this synced folder.
  By default this will be the SSH user. Some synced folder types don't
  support modifying the owner.

* `type` (string) - The type of synced folder. If this is not specified,
  Vagrant will automatically choose the best synced folder option for your
  environment. Otherwise, you can specify a specific type such as "nfs".

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
