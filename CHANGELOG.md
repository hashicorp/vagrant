## 0.5.4 (September 7, 2010)

  - Fix issue with the "exec failed" by running on Tiger as well.
  - Give an error when downloading a box which already exists prior
    to actually downloading the box.

## 0.5.3 (August 23, 2010)

  - Add erubis as a dependency since its rendering of `erb` is sane.
  - Fixed poorly formatted Vagrantfile after `vagrant init`. [GH-142]
  - Fixed NFS not working properly with multiple NFS folders.
  - Fixed chef solo provision to work on Windows. It was expanding a linux
    path which prepended a drive letter onto it.

## 0.5.2 (August 3, 2010)

  - `vagrant up` can be used as a way to resume the VM as well (same as
    `vagrant resume`). [GH-134]
  - Sudo uses "-E" flag to preserve environment for chef provisioners.
    This fixes issues with CentOS. [GH-133]
  - Added "IdentitiesOnly yes" to options when `vagrant ssh` is run to
    avoid "Too Many Authentication Failures" error. [GH-131]
  - Fix regression with `package` not working. [GH-132]
  - Added ability to specify box url in `init`, which populates the
    Vagrantfile with the proper `config.vm.box_url`.

## 0.5.1 (July 31, 2010)

  - Allow specifying cookbook paths which exist only on the VM in `config.chef.cookbooks_path`.
    This is used for specifying cookbook paths when `config.chef.recipe_url` is used. [GH-130]
    See updated chef solo documentation for more information on this.
  - No longer show "Disabling host only networks..." if no host only networks
    are destroyed. Quiets `destroy`, `halt`, etc output a bit.
  - Updated getting started guide to be more up to date and generic. [GH-125]
  - Fixed error with doing a `vagrant up` when no Vagrantfile existed. [GH-128]
  - Fixed NFS erroring when NFS wasn't even enabled if `/etc/exports` doesn't
    exist. [GH-126]
  - Fixed `vagrant resume` to properly resume a suspended VM. [GH-122]
  - Fixed `halt`, `destroy`, `reload` to where they failed if the VM was
    in a saved state. [GH-123]
  - Added `config.chef.recipe_url` which allows you to specify a URL to
    a gzipped tar file for chef solo to download cookbooks. See the
    [chef-solo docs](http://wiki.opscode.com/display/chef/Chef+Solo#ChefSolo-RunningfromaURL) for more information.
    [GH-121]
  - Added `vagrant box repackage` which repackages boxes which have
    been added. This is useful in case you want to redistribute a base
    box you have but may have lost the actual "box" file. [GH-120]

## Previous

The changelog began with version 0.5.1 so any changes prior to that
can be seen by checking the tagged releases and reading git commit
messages.

