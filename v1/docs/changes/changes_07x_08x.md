---
layout: documentation
title: Changes - 0.7.x to 0.8.x
---
# Changes from Vagrant 0.7.x to 0.8.x

Vagrant 0.8.0 is a major release for Vagrant, on the road to 1.0.
The goal of Vagrant 0.8.0 was performance. You'll find major performance
improvements in this release. Read on for more information.

## VirtualBox 4.1 Support. Previous versions unsupported.

Vagrant 0.8.0 supports VirtualBox 4.1 but drops support for earlier
versions. If you're stuck with VirtualBox 4.0 or earlier, use an earlier
version of Vagrant.

The `lucid32` and `lucid64` boxes will be updated with the latest
guest additions and so on.

## Performance, performance, and more performance

The vast majority of effort in this release has gone into performance. Three
cases were optimized:

1. Load time
2. VirtualBox interaction time
3. SSH time

Load time has been decreased significantly. In some cases you will see
as much as an 80% speedup in this area. What this means is that all
`vagrant` commands appear more responsive. And, yes, `vagrant status`
is very fast now, compared to what it was.

VirtualBox interaction time is the total time that Vagrant spends making
API calls to VirtualBox. Without going into technical details, much of
the Vagrant internals have been re-architected to minimize this time. In
a standard `vagrant up`, the time it takes to get to booting the VM (not
counting importing) should see around 50 to 75% speedups.

SSH time is the total time Vagrant spends making SSH requests in the VM.
I've reworked how SSH execution works internally in Vagrant to reuse
previously opened connections, resulting in less overall SSH handshakes.
This speeds up post-boot speeds in `up`, `reload`, etc. greatly.

Of course I'd still like to optimize this more, but I'm very happy with
the results in this release.

## Minor Bugs and Improvements

Many other minor bugs were fixed and improvements were made. Some highlights:

* The shell provisioner now supports the `inline` option which allows
  you to write scripts as strings inline write into your Vagrantfile.
  This is useful for quick tasks or if you're reading in the command
  from some other source.

* With the Chef provisioner, you can finally do `config.json =` instead
  of doing the hacky `merge!` technique. This makes this provisioner
  much more approachable for newer users.

* You can now specify the owner/group for your shared folders (not NFS).

## The Future

I'm now in "Vagrant 1.0" mode. Vagrant 0.8.0 made big gains
in performance, and I am pleased. I'll continue to optimize Vagrant where I
can, but the focus for Vagrant 0.9.0 will be testing and stability.

I have many big plans for Vagrant after 1.0, but they're large architectural
changes that I simply can't justify making at this point without releasing an
official 1.0 first. There are enough users and companies out there which want
to see a stable, long-term Vagrant release, and I'm focused on releasing this.
