---
layout: "docs"
page_title: "Upgrading Vagrant"
sidebar_current: "installation-upgrading"
description: |-
  If you are upgrading from Vagrant 1.0.x, please read the specific page
  dedicated to that. This page covers upgrading Vagrant in general during the
  1.x series.
---

# Upgrading Vagrant

If you are upgrading from Vagrant 1.0.x, please read the
[specific page dedicated to that](/docs/installation/upgrading-from-1-0.html).
This page covers upgrading Vagrant in general during the 1.x series.

Vagrant upgrades during the 1.x release series are straightforward:

1. [Download](/downloads.html) the new package
2. Install it over the existing package

The installers will properly overwrite and remove old files. It is recommended
that no other Vagrant processes are running during the upgrade process.

Note that Vagrantfile stability for the new Vagrantfile syntax is not
promised until 2.0 final. So while Vagrantfiles made for 1.0.x will
[continue to work](/docs/installation/backwards-compatibility.html),
newer Vagrantfiles may have backwards incompatible changes until 2.0 final.

<div class="alert alert-info alert-block">
  <strong>Run into troubles upgrading?</strong> Please
  <a href="https://github.com/mitchellh/vagrant/issues" class="alert-link">report an issue</a>
  if you run into problems upgrading. Upgrades are meant to be a smooth
  process and we consider it a bug if it was not.
</div>
