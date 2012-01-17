---
layout: documentation
title: Changes - 0.8.x to 0.9.x
---
# Changes from Vagrant 0.8.x to 0.9.x

Vagrant 0.9.0 is a major release and the final 0.x release before
a stable version 1.0. The goal of Vagrant 0.9.0 was compatibility
and finalization of the outward-facing API. As such, 0.9.x introduces
significant _backwards incompatibilities_. Read on for more information.

## Backwards Incompatibilities

Vagrant 0.9.0 introduces numerous backwards incompatibilities in the
syntax of the `Vagrantfile` and available configuration options. Instead
of enumerating the incompatibilities here, we recommend simply upgrading
to 0.9.0 and working your way through the error messages. Vagrant 0.9.0
contains messages for each backwards incompatibility, so it should be a
smooth process to upgrade.

## VirtualBox 4.0 _and_ 4.1 Support.

Vagrant now supports both VirtualBox 4.0.x and 4.1.x. Some people have
been having issues with kernel panics and such in 4.1.x, and this should
provide a smoother transition to future versions.

VirtualBox 4.0 and 4.1 will be supported through 1.0.

## Complete Windows Compatibility

Windows is now fully supported, including all networking features. For
the entire time that Vagrant has been available for Windows, certain
features have been missing, such as host only networking. All of these
incompatibilities are now gone and you should see identical behavior
between Vagrantfiles made on Linux, Mac, and Windows.

Also, JRuby is no longer required for 64-bit Windows. In fact, the
recommended path is to now use the [RubyInstaller](http://rubyinstaller.org/).

## Bridged Networking

Vagrant now fully supports bridged networking, allowing your virtual
machines to appear as physical devices on your network. This is extremely
useful because other devices on your network, such as a mobile phone,
can now communicate with the virtual machine with a dedicated IP.

Bridged networking couldn't be simpler to use:

    config.vm.network :bridged

## The Future

Vagrant 0.9.0 is the final minor release before Vagrant 1.0. Additionally,
the internal architecture is stabalized, so the plan to 1.0 is completely
stability. Additionally, installers will be provided for all platforms
for the 1.0 release.
