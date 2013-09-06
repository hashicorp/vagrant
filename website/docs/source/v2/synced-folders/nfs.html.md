---
page_title: "NFS - Synced Folders"
sidebar_current: "syncedfolder-nfs"
---

# NFS

In some cases the default shared folder implementations (such as VirtualBox
shared folders) have high performance penalties. If you're seeing less
than ideal performance with synced folders, [NFS](http://en.wikipedia.org/wiki/Network_File_System_%28protocol%29)
can offer a solution. Vagrant has built-in support to orchestrate the
configuration of the NFS server on the host and guest for you.

<div class="alert alert-info">
	<p>
		<strong>Windows users:</strong> NFS folders do not work on Windows
		hosts. Vagrant will ignore your request for NFS synced folders on
		Windows.
	</p>
</div>

## Prerequisites

Before using synced folders backed by NFS, the host machine must have
`nfsd` installed, the NFS server daemon. This comes pre-installed on Mac
OS X, and is typically a simple package install on Linux.

Additionally, the guest machine must have NFS support installed. This is
also usually a simple package installation away.

## Root Privilege Requirement

To configure NFS, Vagrant must modify system files on the host. Therefore,
at some point during the `vagrant up` sequence, you may be prompted for
administrative privileges (via the typical `sudo` program). These
privileges are used to modify `/etc/exports` as well as to start and
stop the NFS server daemon.


## Enabling NFS Synced Folders

To enable NFS, just add the `nfs: true` flag onto your synced folder:

```ruby
Vagrant.configure("2") do |config|
  # ...

  config.vm.synced_folder ".", "/vagrant", nfs: true
end
```

If you add this to an existing Vagrantfile that has a running guest machine,
be sure to `vagrant reload` to see your changes.
