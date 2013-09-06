---
page_title: "Boxes"
sidebar_current: "boxes"
---

# Boxes

Boxes are the skeleton from which Vagrant machines are constructed. They are
portable files which can be used by others on any platform that runs Vagrant
to bring up a working environment.

The `vagrant box` utility provides all the functionality for managing
boxes. Boxes must currently be created manually.

Boxes are [provider-specific](/v2/providers/index.html), so you must obtain
the proper box depending on what provider you're using.

If you're interested in more details on the exact file format of
boxes, there is a separate [page dedicated to that](/v2/boxes/format.html), since
it is an advanced topic that general users don't need to know.

## Adding Boxes

Adding boxes is straightforward:

```
$ vagrant box add name url
```

`name` is a logical name by which the box is referenced from the
Vagrantfile. You can put anything you want here, but know that Vagrant
matches the `config.vm.box` directive with this name in order to look up
the box to use.

`url` is the location of the box. This can be a path to your local filesystem
or an HTTP URL to the box remotely.

Vagrant will automatically determine the provider the box was built
for by reading the "metadata.json" file within the box archive. You
may also tell Vagrant what provider the box is for by specifying the
`--provider` flag.

This is recommended as it adds an extra level of verification
to the box you're downloading. Additionally, Vagrant can exit early with
an error if a box with that name and provider already exists, whereas
it must download the entire box before showing such an error in the other
case.

Multiple boxes with the same name can exist as long as they are all
for different providers. The example of listing boxes below shows this,
where there are multiple precise64 boxes, backed by different providers.
This lets a single `config.vm.box` configuration within a Vagrantfile
properly reference boxes across providers.

## Listing Boxes

To view what boxes Vagrant has locally installed, use `vagrant box list`:

```
$ vagrant box list
precise64 (virtualbox)
precise64 (vmware_fusion)
```

Vagrant lists all boxes along with the providers the box is for in parentheses.

## Removing Boxes

Boxes can be removed just as easily as they are added:

```
$ vagrant box remove precise64 virtualbox
```

The two arguments are the logical name of the box and the provider of the
box. The second argument (the provider) is optional. If you have only a single
provider backing that box, it doesn't need to be specified. If you have multiple
providers backing a box and it isn't specified, Vagrant will show an error.
