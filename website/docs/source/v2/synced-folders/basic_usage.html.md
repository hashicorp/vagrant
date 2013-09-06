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

## Enabling

Synced folders are automatically setup during `vagrant up` and
`vagrant reload`.

## Disabling

Shared folders can be disabled by adding the `disabled` option to
any definition:

```ruby
Vagrant.configure("2") do |config|
  config.vm.synced_folder "src/", "/srv/website", disabled: true
end
```

## Modifying the Owner/Group

By default, Vagrant mounts the synced folders with the owner/group set
to the SSH user. Sometimes it is preferable to mount folders with a different
owner and group. It is possible to set these options:

```ruby
config.vm.synced_folder "src/", "/srv/website",
  owner: "root", group: "root"
```
