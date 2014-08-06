---
page_title: "File Uploads - Provisioning"
sidebar_current: "provisioning-file"
---

# File Provisioner

**Provisioner name: `"file"`**

The file provisioner allows you to upload a file from the host machine to
the guest machine.

File provisioning is a simple way to, for example, replicate your local
~/.gitconfig to the vagrant user's home directory on the guest machine so
you won't have to run `git config --global` every time you provision a
new VM.

    Vagrant.configure("2") do |config|
      # ... other configuration

      config.vm.provision "file", source: "~/.gitconfig", destination: ".gitconfig"
    end

Note that, unlike with synced folders, files that are uploaded will not
be kept in sync. Continuing with the example above, if you make further
changes to your local ~/.gitconfig, they will not be immediately reflected
in the copy you uploaded to the guest machine.

## Options

The file provisioner takes only two options, both of which are required:

* `source` (string) - Is the local path of the file to be uploaded.

* `destination` (string) - Is the remote path on the guest machine where
  the file will be uploaded to. The file is uploaded as the SSH user over
  SCP, so this location must be writable to that user. The SSH user can be
  determined by running `vagrant ssh-config`, and defaults to "vagrant".

