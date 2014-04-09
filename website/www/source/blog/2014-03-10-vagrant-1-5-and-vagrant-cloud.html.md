---
page_title: "Vagrant 1.5 and Vagrant Cloud"
title: "Vagrant 1.5 and Vagrant Cloud"
author: "Mitchell Hashimoto"
author_url: https://github.com/mitchellh
---

Vagrant 1.5 is now available! This is a new major release that
adds some incredible new features to Vagrant. We've also obsessed over
[stability](/blog/stability-and-upgrades.html), so we expect this to be the
most stable release, as well.

We're also announcing [Vagrant Cloud](https://vagrantcloud.com), a place
for sharing, discovering, and creating Vagrant environments. Vagrant Cloud
today is a place for managing boxes and
[Vagrant Share](/blog/feature-preview-vagrant-1-5-share.html). In the future,
it'll continue to grow into a much broader vision we have.

Vagrant 1.5 introduces no breaking backwards compatibilities. There are some
configuration options that have changed but they still work and will now just
output deprecation warnings. They'll be removed in a future release.

There are a huge number of features in Vagrant 1.5, more than any other
release Vagrant has ever had. And there are also a huge number of bug fixes
in Vagrant 1.5. The feature highlights:

  * [Vagrant Share](/blog/vagrant-1-5-and-vagrant-cloud.html#features)
  * [Boxes 2.0](/blog/vagrant-1-5-and-vagrant-cloud.html#features)
  * [Rsync Synced Folders](/blog/vagrant-1-5-and-vagrant-cloud.html#features)
  * [Hyper-V](/blog/vagrant-1-5-and-vagrant-cloud.html#features)
  * [SMB Synced Folders](/blog/vagrant-1-5-and-vagrant-cloud.html#features)

You can [download Vagrant now](/downloads.html) or read the
[complete CHANGELOG](https://github.com/mitchellh/vagrant/blob/v1.5.0/CHANGELOG.md).
You can also [sign up for Vagrant Cloud](https://vagrantcloud.com) now.
Otherwise, continue reading for more details about Vagrant 1.5 and
Vagrant Cloud.

READMORE

<a id="features"></a>
### New Features

Vagrant 1.5 is full of many new features. We spent almost a month leading
up to the release of Vagrant 1.5 previewing each of these features. To learn
more about the new features in Vagrant 1.5, please read the preview post
for each:

  * [Vagrant Share](/blog/feature-preview-vagrant-1-5-share.html) - Share
    access to your Vagrant environment to anyone in the world with a simple
    command. Collaboration with Vagrant environments has never been easier.

  * [Boxes 2.0](/blog/feature-preview-vagrant-1-5-boxes-2-0.html) - Versioned
    boxes make it easier to track changes, and box names are now as simple
    as `hashicorp/precise64`. In short: boxes are much more pleasant to use.

  * [Rsync Synced Folders](/blog/feature-preview-vagrant-1-5-rsync.html) -
    Use `rsync` to sync folders between the host and the guest. This creates
    very high performance file writes/reads in exchange for slightly higher
    syncing times. In addition, rsync synced folders allow filesystem
    notification systems (such as inotify) to work properly.

  * [SMB Synced Folders](/blog/feature-preview-vagrant-1-5-hyperv.html) -
    A high-performance synced folder option for Windows users. These synced
    folders use SMB to sync data to and from the guest.

  * [Hyper-V](/blog/feature-preview-vagrant-1-5-hyperv.html) - The first
    provider other than VirtualBox to ship with Vagrant itself. Vagrant can
    now create and manage Vagrant environments backed by Hyper-V. This is
    the first of many providers coming into Vagrant core.

In addition to the above features we highlighted, Vagrant 1.5 has many more that
we didn't have time to cover in dedicated blog posts:

  * **Password-based SSH authentication** - Boxes used with Vagrant no longer
    need to have the "insecure Vagrant key" inside them. Vagrant can now connect
    with password-based authentication and insert a key for you. This lets
    you use almost any off-the-shelf virtual machine with Vagrant.

  * **Plugin management overhaul** - Vagrant now has better dependency
    resolution for plugins, can constrain versions, can update all plugins
    with a single `vagrant plugin update`, and more. The command-line usage
    of the plugin system is the same, but we think that plugins will be much
    more enjoyable to use and manage now.

  * **New guest support: Funtoo, NetBSD, and TinyCore Linux** - Vagrant can
    now manage networks, hostnames, etc. on these operating systems as
    guests.

The documentation for Vagrant has been updated to cover all of these new
features, so you can learn details about each feature in the
[Vagrant documentation](http://docs.vagrantup.com).

In addition to these features, dozens of improvements and bug fixes were
made to Vagrant. You can see these by reading the complete
[CHANGELOG](https://github.com/mitchellh/vagrant/blob/v1.5.0/CHANGELOG.md).

### Vagrant Cloud

Alongside Vagrant 1.5, we're announcing the availability of
[Vagrant Cloud](https://vagrantcloud.com). Vagrant Cloud is a hosted
service for finding boxes, sharing boxes, managing Vagrant Share, and
much more to come.

With the Vagrant Cloud launch, we're
[featuring Chef's pre-built boxes](https://vagrantcloud.com/discover/featured)
for various operating systems. These boxes do not have any provisioners
pre-installed and are a great starting point for any development environments.
They also show how easy it is to find boxes on Vagrant Cloud:
[https://vagrantcloud.com/discover/featured](https://vagrantcloud.com/discover/featured).

Coming very soon to Vagrant Cloud: support for organizations, API access, audit logs
and statistics for box usage, ACLs on Vagrant Shares, custom domains,
and more.

Vagrant Cloud is completely free for now. While we'll eventually charge
for some access to it, most personal usage will likely remain free. Our current
plans for pricing revolve around commercial use and advanced features.

### The Future

Vagrant 1.5 addresses and resolves many major feature requests for core
Vagrant functionality. We've already begun work on Vagrant 1.6, which will
add a few new exciting core features, as well as bring in more providers
into the core of Vagrant.

In 1.6, you'll finally be able to see the status of all created Vagrant
environments from anywhere on your system. No more forgetting you have a
handful of virtual machines running! Vagrant will also have full support
for Windows-based guest machines, finally. And we're planning on adding at
least two providers to core, if not more.

Of course, we have more plans than just this, but this should show you
that we still have much to do, but we're getting there.
