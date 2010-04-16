---
layout: documentation
title: Changes - 0.2.x to 0.3.x
---
# Changes from Version 0.2.x to 0.3.x

Vagrant `0.2.0` was a very stable release for Vagrant. No showstopping bugs were reported
and based on the feedback in `#vagrant`, the mailing list, and twitter, people have been
using Vagrant quite successfully.

This stability allowed us to focus on refinement and new features for Vagrant `0.3.x`.

## Microsoft Windows Support!

Vagrant now officially supports Windows as a host machine. Web developers stuck on
Windows can now develop in linux environments while continuing to use RubyMine or
any text editor you prefer on Windows.

**Windows support is very beta. Its known to work on Windows XP and Windows 7. Windows Vista is untested.**

For a quick-start guide on Windows, see our [Windows setup guide](/docs/getting-started/setup/windows.html).

## `vagrant` Command Changes

`vagrant down` is now `vagrant destroy`. A deprecation warning has been inserted
into `0.3.0` but will be removed completely for any subsequent release.

Additionally, the `vagrant` commands are no longer "git style" binaries. This means
that the `vagrant up` is no longer equivalent to `vagrant-up`. The space is now
mandatory. This was required to improve extensibility and functionality of the
specific commands.

## Improved Packaging

While Vagrant makes it easy to package (and repackage) environments for
distribution, we thought it could be easier. The major annoyance in packaging
was that the MAC address for boxes had to be extracted and packaged manually.

No more! You can now literally just do a `vagrant package` within a Vagrant
environment, and it will package a fully functional environment. You can still
include customizations and so on with the `--include` flag, and these will
continue to work as expected.

## Base Box Packaging with `vagrant package`

Base box creators rejoice! You can now package base boxes using the `vagrant package`
command. This also means that, along with the above change, you no longer need
to "copy down the MAC address," since Vagrant handles this for you. An example,
if you created a base virtual machine named "karmic" (in VirtualBox):

{% highlight bash %}
$ vagrant package --base karmic
{% endhighlight %}

That's all there is to it! No more manual Vagrantfile creation, no more manual
`tar`ing, etc.

## Minor Changes

#### Specifying a Box with `vagrant init`

`vagrant init` now takes an optional argument to specify the base box. Previously,
the generated Vagrantfile used "base" as the box and this always had to be edited.
Now, if you want to use a "karmic" box, for example, just run `vagrant init karmic`.

#### Progress Bars

Importing and exporting VMs now have a nice progress bar (similar to HTTP
box adding). You can visually see the progress of these operations, instead
of blindly waiting for a few minutes. Its a minor change, but it has made
using Vagrant that much more enjoyable.

This change was made possible to do a massive change in
Vagrant's most important dependency: the [VirtualBox gem](http://github.com/mitchellh/virtualbox).
The VirtualBox gem now uses the native C interface to talk with the
VirtualBox API, rather than piggybacking on top of XML files and `VBoxManage`.

#### Chef Solo Role Support

Roles can now be used with chef solo by specifying a path to the roles
directory with `config.chef.roles_path`. Roles can then be added to the
chef run list just like chef server. For more details on how to configure
roles for chef solo, read [the official documentation](http://wiki.opscode.com/display/chef/Chef+Solo#ChefSolo-Roles).

#### Refinement, Refinement, Refinement

While `0.2.x` had no showstopper bugs, it certainly had its share of odd
behavior, edge case bugs, etc. All out-standing bugs in the [issue tracker](http://github.com/mitchellh/vagrant/issues)
have been closed (as of this writing) and Vagrant is more stable than ever.

As always, if you run into any troubles, please report the issue on the
GitHub [issue tracker](http://github.com/mitchellh/vagrant/issues).