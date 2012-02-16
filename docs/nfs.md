---
layout: documentation
title: Documentation - NFS Shared Folders

current: NFS
---
# NFS Shared Folders

Its a long known issue that VirtualBox shared folder performance
degrades quickly as the number of files in the shared folder increases.
As a project reaches 1000+ files, doing simple things like running unit
tests or even just running an app server can be many orders of magnitude
slower than on a native filesystem (e.g. from 5 seconds to over 5 minutes).

If you're seeing this sort of performance drop-off in your shared folders,
<a href="http://en.wikipedia.org/wiki/Network_File_System_(protocol)">NFS</a> shared
folders can offer a solution. Vagrant will orchestrate the configuration
of the NFS server on the host and will mount of the folder on the guest
for you.

**Note:** NFS is not supported on Windows hosts. According to VirtualBox,
shared folders on Windows shouldn't suffer the same performance penalties
as on unix-based systems. If this is not true, feel free to use our [support](/support.html)
channels and maybe we can help you out.

## Performance Benchmarks

[John](http://nickelcode.com) and [I](http://github.com/mitchellh) did extensive
benchmarks using various solutions for the VirtualBox shared folder performance
issue. These benchmarks were run on a real-world rails project with a test
suite of over 6000 tests. We ran a _single_ unit test file and timed the average
of several runs:

<pre>
VirtualBox Shared Folders:         5m 14s
Host File System:                     10s
Native VM File System:                13s
NFS Shared Folders:                   22s
NFS Shared Folders (warm cache):      14s
</pre>

As you can see, while there is a small performance hit compared to having
the files natively on the VM, it is perfectly reasonable versus true
VirtualBox shared folders.

Notice the last line marked with "(warm cache)." During our daily usage
testing, we noticed that NFS really shines when many inodes of the host
filesystem are cached on the VM. Since in real world applications, only a
few files change at a time, we found that we were able to experience nearly
native VM file system performance throughout the day.

## Prerequisites

Before enabling NFS shared folders, there are two main requirements:

* The host machine must have `nfsd` installed, the NFS server
  daemon. This comes pre-installed on Mac OS X 10.5+ (Leopard and higher),
  and is typically a simple package install away on Linux systems.
* The VM must have NFS support installed. Almost all distributions of linux/bsd
  operating systems have this available through their respective package manager.

<div class="alert alert-block alert-notice">
  <h3>Disclaimer / Warning</h3>
  <p>
    Vagrant must edit system files on the host in order to configure NFS.
    Therefore, at some point during the <code>vagrant up</code> sequence,
    you will be prompted by your system for administrator priveleges (via
    the typical <code>sudo</code> command).
  </p>
  <p>
    Vagrant modifies the <code>/etc/exports</code> file. Any previously
    set exported folders will be preserved. While Vagrant is heavily tested,
    the maintainers take no responsibility in any lost data in these files.
  </p>
</div>

## Enabling NFS Shared Folders

NFS shared folders are very easily enabled through the Vagrantfile
configuration by setting a flag on the `config.vm.share_folder` method.
The example below uses NFS shared folders for the main project
directory:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.share_folder("v-root", "/vagrant", ".", :nfs => true)
end
{% endhighlight %}

Setting the `:nfs` flag causes that folder to be mounted via
NFS.

## NFS customization

[NFS exports](http://linux.die.net/man/5/exports) have quite a few configurable
options. Some of these are exposed via the [Vagrantfile](/docs/vagrantfile.html).
If you find an option you'd like exposed, please report a GitHub issue and
we'll try to add it ASAP.
