---
layout: "docs"
page_title: "Box File Format"
sidebar_current: "boxes-format"
description: |-
  The box file format for Vagrant has changed from only supporting VirtualBox to
  supporting a number different providers and box formats.
---

# Box File Format

In the past, boxes were just [tar files](https://en.wikipedia.org/wiki/Tar_\(computing\))
of VirtualBox exports. With Vagrant supporting multiple
[providers](/docs/providers/) and [versioning](/docs/boxes/versioning.html)
now, box files are slightly more complicated.

Box files made for Vagrant 1.0.x (the VirtualBox export `tar` files) continue
to work with Vagrant today. When Vagrant encounters one of these old boxes,
it automatically updates it internally to the new format.

Today, there are three different components:

* Box File - This is a compressed (`tar`, `tar.gz`, `zip`) file that is specific
  to a single provider and can contain anything. Vagrant core does not ever
  use the contents of this file. Instead, they are passed to the provider.
  Therefore, a VirtualBox box file has different contents from a VMware
  box file and so on.

* Box Catalog Metadata - This is a JSON document (typically exchanged
  during interactions with [HashiCorp's Vagrant Cloud](/docs/vagrant-cloud))
  that specifies the name of the box, a description, available
  versions, available providers, and URLs to the actual box files
  (next component) for each provider and version. If this catalog
  metadata does not exist, a box file can still be added directly, but
  it will not support versioning and updating.

* Box Information - This is a JSON document that can provide additional
  information about the box that displays when a user runs
  `vagrant box list -i`. More information is provided [here](/docs/boxes/info.html).

The first two components are covered in more detail below.

## Box File

The actual box file is the required portion for Vagrant. It is recommended
you always use a metadata file alongside a box file, but direct box files
are supported for legacy reasons in Vagrant.

Box files are compressed using `tar`, `tar.gz`, or `zip`. The contents of the
archive can be anything, and is specific to each
[provider](/docs/providers/). Vagrant core itself only unpacks
the boxes for use later.

Within the archive, Vagrant does expect a single file:
`metadata.json`.  This is a JSON file that is completely unrelated to
the above box catalog metadata component; there is only one
`metadata.json` per box file (inside the box file), whereas one
catalog metadata JSON document can describe multiple versions of the
same box, potentially spanning multiple providers.

`metadata.json` must contain at least the "provider" key with the
provider the box is for. Vagrant uses this to verify the provider of
the box. For example, if your box was for VirtualBox, the
`metadata.json` would look like this:

```json
{
  "provider": "virtualbox"
}
```

If there is no `metadata.json` file or the file does not contain valid JSON
with at least a "provider" key, then Vagrant will error when adding the box,
because it cannot verify the provider.

Other keys/values may be added to the metadata without issue. The value
of the metadata file is passed opaquely into Vagrant and plugins can make
use of it. At this point, Vagrant core does not use any other keys in this
file.

## Box Metadata

The metadata is an optional component for a box (but highly recommended)
that enables [versioning](/docs/boxes/versioning.html), updating, multiple
providers from a single file, and more.

<div class="alert alert-block alert-info">
  <strong>You do not need to manually make the metadata.</strong> If you
  have an account with <a href="/docs/vagrant-cloud">HashiCorp's Vagrant Cloud</a>, you
  can create boxes there, and HashiCorp's Vagrant Cloud automatically creates
  the metadata for you. The format is still documented here.
</div>

It is a JSON document, structured in the following way:

```json
{
  "name": "hashicorp/precise64",
  "description": "This box contains Ubuntu 12.04 LTS 64-bit.",
  "versions": [
    {
      "version": "0.1.0",
      "providers": [
        {
          "name": "virtualbox",
          "url": "http://somewhere.com/precise64_010_virtualbox.box",
          "checksum_type": "sha1",
          "checksum": "foo"
        }
      ]
    }
  ]
}
```

As you can see, the JSON document can describe multiple versions of a box,
multiple providers, and can add/remove providers in different versions.

This JSON file can be passed directly to `vagrant box add` from the
local filesystem using a file path or via a URL, and Vagrant will
install the proper version of the box. In this case, the value for the
`url` key in the JSON can also be a file path. If multiple providers
are available, Vagrant will ask what provider you want to use.
