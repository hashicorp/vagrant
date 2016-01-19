---
layout: "docs"
page_title: "Upgrading from Vagrant 1.0"
sidebar_current: "installation-1-0-upgrading"
description: |-
  The upgrade process from 1.0.x to 1.x is straightforward. Vagrant is
  backwards compatible with Vagrant 1.0.x, so you can simply reinstall Vagrant
  over your previous installation by downloading the latest package and
  installing it using standard procedures for your operating system.
---

# Upgrading From Vagrant 1.0.x

The upgrade process from 1.0.x to 1.x is straightforward. Vagrant is quite
[backwards compatible](/docs/installation/backwards-compatibility.html)
with Vagrant 1.0.x, so you can simply reinstall Vagrant
over your previous installation by downloading the latest package and
installing it using standard procedures for your operating system.

As the [backwards compatibility](/docs/installation/backwards-compatibility.html)
page says, **Vagrant 1.0.x plugins will not work with Vagrant 1.1+**. Many
of these plugins have been updated to work with newer versions of Vagrant,
so you can look to see if they've been updated. If not however, you will have
to remove them before upgrading.

It is recommended you remove _all_ plugins before upgrading, and then slowly
add back the plugins. This usually makes for a smoother upgrade process.

<div class="alert alert-warning" role="alert">
  <strong>If your version of Vagrant was installed via Rubygems</strong>, you
  must uninstall the old version prior to installing the package for the
  new version of Vagrant. The Rubygems installation is no longer supported.
</div>
