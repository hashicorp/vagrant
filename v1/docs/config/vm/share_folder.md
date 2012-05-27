---
layout: documentation
title: Documentation - Vagrantfile - config.vm.share_folder

current: Vagrantfile
---
# config.vm.share_folder

Configuration key: `config.vm.share_folder`

This directive is used to configure shared folders on the virtual
machine and may be used multiple times in a Vagrantfile. Shared folders
specify folders that are on the host machine that become available
on the guest machine, so that edits on either side are immediately
visible on both the host and the guest.

Shared folders are easy to configure:

{% highlight ruby %}
Vagrant::Config.run do |config|
  # ...
  config.vm.share_folder "foo", "/guest/path", "/host/path"
end
{% endhighlight %}

The above would create a shared folder mapping named "foo" (a logical
name), from "/host/path" on the host to "/guest/path" on the guest. The
host path can be a relative path, which is expanded relative to the
directory where the main project Vagrantfile is.

Additional options may be passed in as an options hash for a 4th parameter.
The support options are:

* `:create` - If set to `true` and the host path doesn't exist, Vagrant
  will automatically attempt to create it. Default: `false`
* `:nfs` - If set to `true`, then the shared folder will be shared using
  NFS. For more information, read about [NFS shared folders](/docs/nfs.html).
* `:transient` - If set to `true`, then the shared folder definition will
  not be persisted across restarts.

Additionally, there are certain options that have an effect only on
NFS shared folders:

* `:map_uid` - The UID that modifications to the shared folder map to on
  the host machine. By default, Vagrant will use the UID of the owner of
  the folder.
* `:map_gid` - The GID that modifications to the shared folder map to on
  the host machine. By default, Vagrant will use the GID of the owner of
  the folder.
* `:nfs_version` - This is the NFS version that will be used as the format
  for the mount.
