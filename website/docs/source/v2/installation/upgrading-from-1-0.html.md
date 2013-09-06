---
page_title: "Upgrading from Vagrant 1.0"
sidebar_current: "installation-upgrading-1-0"
---

# Upgrading From Vagrant 1.0.x

The upgrade process from 1.0.x to 1.x is straightforward. Vagrant is quite
[backwards compatible](/v2/installation/backwards-compatibility.html)
with Vagrant 1.0.x, so you can simply reinstall Vagrant
over your previous installation by downloading the latest package and
installing it using standard procedures for your operating system.

As the [backwards compatibility](/v2/installation/backwards-compatibility.html)
page says, **Vagrant 1.0.x plugins will not work with Vagrant 1.1+**. Many
of these plugins have been updated to work with newer versions of Vagrant,
so you can look to see if they've been updated. If not however, you'll have
to remove them before upgrading.

It is recommended you remove _all_ plugins before upgrading, and then slowly
add back the plugins. This usually makes for a smoother upgrade process.

**However**, if your version of Vagrant was installed via RubyGems, then
you must `gem uninstall` the old version prior to installing the package for
the latest version of Vagrant. The RubyGems-based installation method has
been removed.
