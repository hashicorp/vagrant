---
sidebar_current: "installation-upgrading-1-0"
---

# Upgrading From Vagrant 1.0.x

The upgrade process from 1.0.x to 1.x is straightforward. Vagrant is quite
[backwards compatible](/v2/installation/backwards-compatibility.html)
with Vagrant 1.0.x, so you can simply reinstall Vagrant
over your previous installation by downloading the latest package and
installing it using standard procedures for your operating system.

**However**, if your version of Vagrant was installed via RubyGems, then
you must `gem uninstall` the old version prior to installing the package for
the latest version of Vagrant. The RubyGems-based installation method has
been removed.
