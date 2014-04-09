---
page_title: "Vagrant 1.5 Feature Preview: Hyper-V, SMB Synced Folders, Windows"
title: "Feature Preview: Hyper-V, SMB Synced Folders, Windows"
author: "Mitchell Hashimoto"
author_url: https://github.com/mitchellh
---

Vagrant has worked on Windows for over four years. Vagrant has worked
_well_ on Windows for about two years. With Vagrant 1.5, Vagrant is
_excellent_ on Windows with dozens of bug fixes and a couple big Windows-only
features: Hyper-V and SMB synced folders.

Vagrant 1.5 will ship with a [Hyper-V](http://en.wikipedia.org/wiki/Hyper-V)
provider out of the box. This is big news! This is the first provider other
than VirtualBox to ship with Vagrant itself (with more to come). And, Hyper-V
comes built-in to almost all editions of Windows 8+, meaning Vagrant works
with nothing more than a Windows computer for most people.

Additionally, Windows users have the option now to use
[SMB](http://en.wikipedia.org/wiki/Server_Message_Block) synced folders.
SMB is a technology built right into Windows, just like Hyper-V, making
it easy for Windows users to get high performance synced folders out of
the box.

Read on to learn more about these features.

READMORE

### Thank You Microsoft

I'd like to start this post off with a big thanks to
[MS OpenTech](http://msopentech.com/). MS OpenTech did most of the hard
work implementing the Hyper-V and SMB synced folder features.

I only had to merge the code and make it more "Vagrant-friendly," which
is far easier than the hard technical details to make the features work.

MS OpenTech will continue improving Vagrant for Windows in the coming
months, adding more features and support across the board for Windows.
The biggest feature that is on the way is first class support for
Windows VMs.

Thank you MS OpenTech!

### Hyper-V

Hyper-V is a native hypervisor built by Microsoft that ships with
most installations of Windows 8+. While it is built by Microsoft, it
is able to virtualize any modern x86/x64 operating system, including
all major distributions of Linux. Of course, it is able to run Windows
very well, too.

With Vagrant 1.5, Hyper-V is a provider built-in to Vagrant. No additional
plugin installs are necessary; just install Vagrant and you're ready.

<div class="center">
	<img src="/images/blog/hyperv_preview.gif" alt="Vagrant + Hyper-V Example">
</div>

A downside of Hyper-V: once it is enabled, no other virtualization technology
can be used (such as VirtualBox or VMware), so it is an all-in or all-out
technology choice. The upside, however, is that it is built-in to Windows with no additional
software installs.

Vagrant 1.5 will be the first iteration of the Hyper-V provider. The VirtualBox
and VMware providers are both extremely mature and work very well. While
the Hyper-V provider works, we expect there to be some bugs and loose ends
that we'll be improving over upcoming releases.

### SMB Synced Folders

Along with the [RSync Synced Folders](/blog/feature-preview-vagrant-1-5-rsync.html)
coming in Vagrant 1.5, we're introducing support for SMB as a mechanism
for synced folders.

SMB is a technology built into Windows that allows you to share any
Windows folder over the network. For Vagrant, we use this mechanism to
create a bi-directional folder share with Vagrant environments.

This is the preferred synced folder mechanism for use with the Hyper-V
provider, but is not limited to only Hyper-V. SMB is available as a higher
performance option for VirtualBox, similar to NFS for Linux.

You can explicitly enable the folder, as usual:

<pre class="prettyprint lang-ruby">
config.vm.synced_folder ".", "/vagrant", type: "smb"
</pre>

Or, if you specify nothing, SMB will be used by default if VM
shared folders aren't available. Therefore, it is recommended to keep your
Vagrant environment compatible with all operating systems to just leave off
the type.

### Other Windows Improvements

Vagrant 1.5 has dozens of bug fixes to improve the experience of Vagrant
on Windows. Even if the features above aren't useful to you as a Vagrant
user on Windows, Vagrant 1.5 is highly recommended.

In addition to little bug fixes, the Vagrant MSI installers starting with
Vagrant 1.5 will be properly signed. Over time, this should eliminate most
warnings when Vagrant is downloaded and installed on Windows, and should
improve confidence when you download a Vagrant update that it has not
been tampered with.

### Next

This is just the first step in better supporting Windows. We have a few
more bugs to fix, improvements to make to both Hyper-V and SMB, and more.
Most importantly, we're gunning to support Windows guests more fully in
future releases of Vagrant.

There are even more features and improvements coming in Vagrant 1.5,
but this concludes the feature preview series for Vagrant 1.5. Expect a
release soon.
