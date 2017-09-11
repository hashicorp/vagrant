---
layout: "docs"
page_title: "File Uploads - Provisioning"
sidebar_current: "provisioning-file"
description: |-
  The Vagrant file provisioner allows you to upload a file or directory from the
  host machine to the guest machine.
---

# File Provisioner

**Provisioner name: `"file"`**

The Vagrant file provisioner allows you to upload a file or directory from the
host machine to the guest machine.

File provisioning is a simple way to, for example, replicate your local
~/.gitconfig to the vagrant user's home directory on the guest machine so
you will not have to run `git config --global` every time you provision a
new VM.

    Vagrant.configure("2") do |config|
      # ... other configuration

      config.vm.provision "file", source: "~/.gitconfig", destination: ".gitconfig"
    end

If you want to upload a folder to your guest system, it can be accomplished by
using a file provisioner seen below. When copied, the resulting folder on the guest will
replace `folder` as `newfolder` and place its on the guest machine. Note that if
you'd like the same folder name on your guest machine, make sure that the destination
path has the same name as the folder on your host.

    Vagrant.configure("2") do |config|
      # ... other configuration

      config.vm.provision "file", source: "~/path/to/host/folder", destination: "$HOME/remote/newfolder"
    end

Prior to copying `~/path/to/host/folder` to the guest machine:

        folder
        ├── script.sh
        ├── otherfolder
        │   └── hello.sh
        ├── goodbye.sh
        ├── hello.sh
        └── woot.sh

        1 directory, 5 files

After to copying `~/path/to/host/folder` into `$HOME/remote/newfolder` to the guest machine:

        newfolder
        ├── script.sh
        ├── otherfolder
        │   └── hello.sh
        ├── goodbye.sh
        ├── hello.sh
        └── woot.sh

        1 directory, 5 files

Note that, unlike with synced folders, files or directories that are uploaded
will not be kept in sync. Continuing with the example above, if you make
further changes to your local ~/.gitconfig, they will not be immediately
reflected in the copy you uploaded to the guest machine.

The file uploads by the file provisioner are done as the
_SSH or PowerShell user_. This is important since these users generally
do not have elevated privileges on their own. If you want to upload files to
locations that require elevated privileges, we recommend uploading them
to temporary locations and then using the
[shell provisioner](/docs/provisioning/shell.html)
to move them into place.

## Options

The file provisioner takes only two options, both of which are required:

* `source` (string) - Is the local path of the file or directory to be
  uploaded.

* `destination` (string) - Is the remote path on the guest machine where
  the source will be uploaded to. The file/folder is uploaded as the SSH user
  over SCP, so this location must be writable to that user. The SSH user can be
  determined by running `vagrant ssh-config`, and defaults to "vagrant".

## Caveats

While the file provisioner does support trailing slashes or "globing", this can
lead to some confusing results due to the underlying tool used to copy files and
folders between the host and guests. For example, if you have a source and
destination with a trailing slash defined below:

      config.vm.provision "file", source: "~/pathfolder", destination: "/remote/newlocation/"

You are telling vagrant to upload `~/pathfolder` under the remote dir `/remote/newlocation`,
which will look like:

        newlocation
        ├── pathfolder
        │   └── file.sh

        1 directory, 2 files

This behavior can also be achieved by defining your file provisioner below:

      config.vm.provision "file", source: "~/pathfolder", destination: "/remote/newlocation/pathfolder"

Another example is using globing on the host machine to grab all files within a
folder, but not the top level folder itself:

      config.vm.provision "file", source: "~/otherfolder/.", destination: "/remote/otherlocation"

The file provisioner is defined to include all files under `~/otherfolder`
to the new location `/remote/otherlocation`. This idea can be achieved by simply
having your destination folder differ from the source folder:

      config.vm.provision "file", source: "/otherfolder", destination: "/remote/otherlocation"
