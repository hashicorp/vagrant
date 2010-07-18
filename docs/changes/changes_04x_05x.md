---
layout: documentation
title: Changes - 0.4.x to 0.5.x
---
# Changes in Vagrant 0.5.x

## VirtualBox 3.2 Requirement

Although this has been true since Vagrant 0.4.2, I want to make a brief
note of it here in a more prominent release announcement. Vagrant now only
supports VirtualBox 3.2.x. Supporting 3.1.x in addition to 3.2.x was introducing
complicated branch logic in the internals of Vagrant, opening up many areas
for bugs to easily slip through. Because of this, I've decided to focus on VirtualBox
3.2.x. If you must use VirtualBox 3.1.x, please use an earlier version of Vagrant
(0.4.1 works nicely).

## NFS Shared Folders

It is a well known fact that VirtualBox shared folder performance degrades
rapidly as the number of files in the shared folders increases (or if you
don't know this now, you'll find out in the future as your project grows).
Having worked on many multi-thousand file web projects, my coworkers and I
quickly found that VirtualBox shared folders were too slow, and we had to
resort to using tools such as rsync or unison to sync the "/vagrant" folder
to some other non-shared-folder directory. This manual syncing process went
against everything Vagrant believes in: not getting in your way and making
development easier.

We found that an easy solution was to punt VirtualBox shared folders and
use NFS (http://en.wikipedia.org/wiki/Network_File_System_(protocol)) instead.
Therefore, Vagrant 0.5 comes with built-in support for setting up and mounting
NFS shared folders. If you're finding that your shared folders are becoming
much slower than your native file system, I recommend you switch to using NFS.

More details, including benchmarks, can be found at the [NFS documentation page](/docs/nfs.html).

## SIGINT (Ctrl-C) Finally Works

Thanks to some heavy internal refactoring and all out change, SIGINT (Ctrl-C)
finally works during `vagrant` commands! During Vagrant 0.1 to 0.2, Vagrant
used to leave VirtualBox in a broken state if you did Ctrl-C. And for 0.3 to
0.4, it used to exit, but you were forced to manually clean up after Vagrant.
And if you did a SIGINT before Vagrant could persist the VM UUID, then
`vagrant destroy` didn't even work! UGH!

But now, SIGINT anytime you want, and Vagrant will properly clean up after
itself. Yes, you can even send an INT signal during an import or export,
and everything will work out.

## Huge Internal Changes

Most of the work from 0.4.x to 0.5.x has been "under the hood" in preparation
for future features. I expect these changes to bring about more stability in
the long run to Vagrant, while possibly causing some very minor short term
bugs, though my coworkers and I have been using Vagrant 0.5 in-house for a few
weeks now without issue.
