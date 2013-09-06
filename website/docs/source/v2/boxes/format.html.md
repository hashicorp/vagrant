---
page_title: "Box File Format"
sidebar_current: "boxes-format"
---

# Box File Format

In the past, boxes were just [tar files](http://en.wikipedia.org/wiki/Tar_\(computing\))
of VirtualBox exports. With Vagrant supporting multiple providers, box files
are now tar files where the contents differ for each provider. They are
still tar files, but they may now optionally be [gzipped](http://en.wikipedia.org/wiki/Gzip)
as well.

Box files made for Vagrant 1.0.x and VirtualBox continue to work with
Vagrant 1.1+ and the VirtualBox provider.

The only file required within a box is a "metadata.json" file. This is
a [JSON](http://www.json.org/) file that has a top-level object that
can contain any metadata about the box. Vagrant requires that a "provider"
key exists in this metadata with the name of the provider the box is made
for.

The "metadata.json" file for a VirtualBox box:

```json
{
  "provider": "virtualbox"
}
```

If there is no metadata.json file or the file does not contain valid JSON
with at least a "provider" key, then Vagrant will error when adding the box.
