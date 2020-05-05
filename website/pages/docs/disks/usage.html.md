---
layout: 'docs'
page_title: 'Vagrant Disk Usage'
sidebar_current: 'disks-usage'
description: |-
  Various Vagrant Disk examples
---

# Basic Usage

<div class="alert alert-warning">
  <strong>Warning!</strong> This feature is experimental and may break or
  change in between releases. Use at your own risk. It currently is not officially
  supported or functional.

This feature currently reqiures the experimental flag to be used. To explicitly enable this feature, you can set the experimental flag to:

```
VAGRANT_EXPERIMENTAL="disks"
```

Please note that `VAGRANT_EXPERIMENTAL` is an environment variable. For more
information about this flag visit the [Experimental docs page](/docs/experimental/)
for more info. Without this flag enabled, any disks defined will not be configured.

Also note that the examples below use the VirtualBox provider, which is the current
supported providier for this feature.

</div>

Below are some very simple examples of how to use Vagrant Disks with the VirtualBox provider.

## Basic Examples

### Resizing your primary disk

Sometimes, the primary disk for a guest is not large enough and you will need to
add more space. To resize a disk, you can simply add a config like this below
to expand the size of your guests drive:

```ruby
config.vm.disk :disk, size: "100GB", primary: true
```

Note: the `primary: true` is what tells Vagrant to expand the guests main drive.
Without this option, Vagrant will instead attach a _new_ disk to the guest.

For example, this Ubuntu guest will now come with 100GB of space, rather than the default:

```ruby
Vagrant.configure("2") do |config|
  config.vm.define "hashicorp" do |h|
    h.vm.box = "hashicorp/bionic64"
    h.vm.provider :virtualbox

    h.vm.disk :disk, size: "100GB", primary: true
  end
end
```

It should be noted that due to how VirtualBox functions, it is not possible to shrink
the size of a disk.

### Attaching new disks

Vagrant can attach multiple disks to a guest using the VirtualBox provider. An example
of attaching a single disk to a guest with 10 GB of storage can be found below:

```ruby
Vagrant.configure("2") do |config|
  config.vm.define "hashicorp" do |h|
    h.vm.box = "hashicorp/bionic64"
    h.vm.provider :virtualbox

    h.vm.disk :disk, size: "10GB", name: "extra_storage"
  end
end
```

Optionally, if you need to attach many disks, you can use Ruby to generate multiple
disks for Vagrant to create and attach to your guest:

```ruby
Vagrant.configure("2") do |config|
  config.vm.define "hashicorp" do |h|
    h.vm.box = "hashicorp/bionic64"
    h.vm.provider :virtualbox

    (0..3).each do |i|
      h.vm.disk :disk, size: "5GB", name: "disk-#{i}"
    end
  end
end
```

Note: Virtualbox only allows for up to 30 disks to be attached to a given SATA Controller,
and this number includes the primary disk! Attempting to configure more than 30 will
result in a Vagrant error.

### Removing Disks

If you have removed a disk from your Vagrant config and wish for it to be detached from the guest,
you will need to `vagrant reload` your guest to apply these changes. **NOTE:** Doing so
will also delete the medium from your hard drive.
