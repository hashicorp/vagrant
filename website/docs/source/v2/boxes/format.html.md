---
page_title: "Box File Format"
sidebar_current: "boxes-format"
---

# Box File Format

In the past, boxes were just [tar files](http://en.wikipedia.org/wiki/Tar_\(computing\))
of VirtualBox exports. With Vagrant supporting multiple
[providers](/v2/providers/index.html) and [versioning](/v2/boxes/versioning.html)
now, box files are slightly more complicated.

Box files made for Vagrant 1.0.x (the VirtualBox export tar files) continue
to work with Vagrant today. When Vagrant encounters one of these old boxes,
it automatically updates it internally to the new format.

Today, box files are split into two different components:

* Box Metadata - This is a JSON document that specifies the name of the box,
  a description, available versions, available providers, and URLs to the
  actual box files (next component) for each provider and version. If this
  metadata doesn't exist, a box file can still be added directly, but it
  will not support versioning and updating.

* Box File - This is a compressed (tar, tar.gz, zip) file that is specific
  to a single provider and can contain anything. Vagrant core doesn't ever
  use the contents of this file. Instead, they are passed to the provider.
  Therefore, a VirtualBox box file has different contents from a VMware
  box file and so on.

Each component is covered in more detail below.

## Box Metadata

The metadata is an optional component for a box (but highly recommended)
that enables [versioning](/v2/boxes/versioning.html), updating, multiple
providers from a single file, and more.

<div class="alert alert-block alert-info">
<strong>You don't need to manually make the metadata.</strong> If you
have an account with <a href="#">Vagrant Cloud</a>, you
can create boxes there, and Vagrant Cloud automatically creates
the metadata for you. The format is still documented here.
</div>

It is a JSON document, structured in the following way:

```json
{
  "name": "hashicorp/precise64",
  "description": "This box contains Ubuntu 12.04 LTS 64-bit.",
  "versions": [{
    "version": "0.1.0",
    "providers": [{
      "name": "virtualbox",
      "url": "http://somewhere.s3.com/precise64_010_virtualbox.box"
    }]
  }]
}
```

As you can see, the JSON document can describe multiple versions of a box,
multiple providers, and can add/remove providers in different versions.

This JSON file can be passed directly to `vagrant box add` and Vagrant
will install the proper version of the box. If multiple providers are
available, Vagrant will ask what provider you want to use.

## Box File

The actual box file is the required portion for Vagrant. It is recommended
you always use a metadata file alongside a box file, but direct box files
are supported for legacy reasons in Vagrant.

Box files are compressed using tar, tar.gz, or zip. The contents of the
archive can be anything, and is specific to each
[provider](/v2/providers/index.html). Vagrant core itself only unpacks
the boxes for use later.

Within the archive, Vagrant does expect a single file: "metadata.json".
This is a JSON file that is completely unrelated to the above "box metadata"
component. This file must contain at least the "provider" key with the
provider the box is for. For example, if your box was for VirtualBox,
the metadata.json would look like this:

```json
{
  "provider": "virtualbox"
}
```

If there is no metadata.json file or the file does not contain valid JSON
with at least a "provider" key, then Vagrant will error when adding the box.
