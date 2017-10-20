---
layout: "vagrant-cloud"
page_title: "Discovering Vagrant Boxes"
sidebar_current: "vagrant-cloud-boxes-catalog"
---

# Discovering Vagrant Boxes

Vagrant Cloud serves a public, searchable index of Vagrant boxes. It's easy to find
boxes you can use with Vagrant that contain the technologies you need
for a Vagrant environment.

You don't need a Vagrant Cloud account to use public boxes.

1. Go to the [Box search page](https://vagrantcloud.com/boxes/search)

1. Once you find a box, click its name to learn more about it.

1. When you're ready to use it, copy the name, such as "hashicorp/precise64"
   and initialize your Vagrant project with `vagrant init hashicorp/precise64`.
   Or, if you already have a Vagrant project created, modify the Vagrantfile
   to use the box: `config.vm.box = "hashicorp/precise64"`

## Provider Support

Not all boxes are available for all providers. You may need
to sort by a provider that you have on your local system
to narrow down your search.

## Choosing the Right Box

As with all software and configuration used from a public source,
it's important to keep in mind whose box you're using. Here
are some things to note when you're choosing a box:

- __The username of the user__. If it's `bento` or `canonical`, you can likely
trust the box more than an anonymous user
- __The number of downloads of the box__. Heavily downloaded boxes
are likely vetted more often by other members of the community. Hashicorp
responds to reports of malicious software distributed via Vagrant Cloud
and takes down boxes
- __The latest release date__. More up-to-date boxes contain up-to-date
software
- __Availability of the box download__. Vagrant Cloud periodically checks if box
has is publicly accessible. You can see this information on the box
page next to the provider
