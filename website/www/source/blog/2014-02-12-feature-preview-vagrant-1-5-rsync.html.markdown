---
page_title: "Vagrant 1.5 Feature Preview: Rsync Synced Folders"
title: "Feature Preview: Rsync Synced Folders"
author: Mitchell Hashimoto
author_url: https://github.com/mitchellh
---

Vagrant 1.5 is going to be the biggest release of Vagrant since 1.1,
with dozens of new features and improvements coming in. Don't worry,
we've also obsessed over [stability](/blog/stability-and-upgrades.html),
so we expect it'll be one of the most stable upgrades, too.

Because Vagrant 1.5 will be so feature-packed, we're doing a series of
blog posts that highlight the upcoming features so you know what to look
forward to and how to use them. These posts will be
weekly on Wednesdays, so keep an eye out for them!

We're going to kick off the series by introducing
[rsync](http://en.wikipedia.org/wiki/Rsync) synced folders. These synced
folders offer incredible I/O performance at the expense of a little bit of
latency. Read on to learn more.

READMORE

### Introducing Rsync Synced Folders

Rsync synced folders use [rsync](http://rsync.samba.org/) to sync files
to the guest machine. They are configured just as easily as any other synced folder,
by just specifying the "rsync" type:

<pre class="prettyprint">
config.vm.synced_folder ".", "/vagrant", type: "rsync"
</pre>

As long as <code>rsync</code> is installed in both the host and the guest,
this will _just work_. Since rsync is a standard utility for Mac and most
Linux distributions, this just works most of the time! For Windows users,
[msysgit](https://code.google.com/p/msysgit/),
[MinGW](http://www.mingw.org/),
and [Cygwin](http://www.cygwin.org)
all provide rsync.

As an added benefit, Vagrant 1.5 knows how to install rsync for most
major operating systems, and will do this automatically for you by
default within the guest machine if `rsync` cannot be found.

When you execute `vagrant up` or `vagrant reload`, Vagrant will sync
the data to the guest machine. In addition to these commands, Vagrant
has a new command `vagrant rsync` that will only sync rsync folders
that are defined.

Unlike VM shared folders and NFS, rsync is a one-time sync from the
host machine to the guest machine. Changes to the folder after the
sync is complete won't be visible in the guest machine until you
force another sync with a command such as `vagrant rsync`. Luckily,
Vagrant 1.5 will provide a way to auto-sync rsync synced folders.

### Auto-Syncing

By default, the folder syncing only happens when you manually execute
a `vagrant up`, `vagrant reload`, or `vagrant rsync`. Part of the magic
of Vagrant, though, has always been for changes to just appear in the
guest machine.

Rsync synced folders don't have this magic property by default because
unlike VM shared folders or NFS, rsync doesn't continue to run in the
background to propagate any changes. And Vagrant itself doesn't keep any
background processes running after it finishes executing, so by default
changes won't be seen.

But because this is such a useful feature of Vagrant, Vagrant 1.5 has a
`vagrant rsync-auto` command. This command runs forever (until you Ctrl-C),
watches any defined rsync synced folders, and automatically syncs changes
as you make them.

```
$ vagrant rsync-auto
==> default: Watching: /home/mitchellh/work/frontend
    default: Changes! Syncing /vagrant
...
```

This command uses system-specific APIs to detect file changes, rather than
polling the file system. Therefore, this command sits idle most of the time
and consumes only a small amount of RAM.

Changes are usually picked up in less than a second, and Vagrant only
syncs changes over a compressed connection to use as little bandwidth as
possible. As a result, changes appear in the guest machine quite fast.

We realize this workflow is a bit different than what you're used to
with Vagrant, but it is a minor change necessitated by the technical
differences of rsync versus other available synced folder mechanisms.

### Performance and Benefits

Because `rsync` copies the files directly onto the remote filesystem,
performance is _fantastic_. For a comparison to NFS or VM shared folders,
see my personal blog post
[comparing filesystem performance in virtual machines](http://mitchellh.com/comparing-filesystem-performance-in-virtual-machines).
With rsync, you'll see the "VirtualBox native" performance numbers.

Unlike NFS and VM shared folders, filesystem notifications work in the
guest machine with rsync synced folders. So, if you use
[Guard](http://guardgem.org/) or something like it, it will now work with
Vagrant!

Also unlike NFS or VM shared folders, filesystem permissions are not
tampered with in the guest machine. NFS and VM shared folders both change
the way file permissions work that is fine most of the time, but can be
really disruptive for some workflows. With rsync, because files are just copied
onto the guest machine, permissions work as you would expect.

Rsync synced folders only requires `rsync` to be available in the guest
machine, so it works on virtual machines that don't have guest additions
installed. This is great for specialized operating systems where guest
additions that require invasive kernel modules won't compile, but a
relatively standard C program such as rsync will.

For Windows users, rsync finally provides a cross-platform alternative
to VM shared folders that works out of the box with Vagrant. While NFS
is available for Windows, Vagrant doesn't currently work with it, so
Vagrant would fall back to VM shared folders.

### Choices, choices, choices!

With the introduction of rsync synced folders, users of Vagrant now
have three choices out of the box for synced folders: VM shared folders,
NFS, or rsync.

NFS and VM shared folders are _not deprecated in any way_ and will be
fully supported and improved for the foreseeable future. Vagrant has always
been about choice and working with the technologies that work best for you
and your team and rsync is now another really great choice Vagrant offers you.

### What's Next?

Rsync synced folders will be available out of the box with Vagrant 1.5.
They are also
[fully documented](https://github.com/mitchellh/vagrant/blob/master/website/docs/source/v2/synced-folders/rsync.html.md)
already, so the documentation will cover all aspects of rsync synced
folders immediately when 1.5 is released.

And that is only one of dozens of features of equal or greater caliber
coming to Vagrant 1.5. Stay tuned next week when we cover another
feature! Vagrant 1.5 will have quite a few surprises, we're sure,
that should make both new and experienced Vagrant users very happy.
