---
layout: "docs"
page_title: "Installing Vagrant"
sidebar_current: "installation"
description: |-
  Installing Vagrant is extremely easy. Head over to the Vagrant downloads page
  and get the appropriate installer or package for your platform. Install the
  package using standard procedures for your operating system.
---

# Installing Vagrant

Installing Vagrant is extremely easy. Head over to the
[Vagrant downloads page](/downloads.html) and get the appropriate installer or
package for your platform. Install the package using standard procedures for
your operating system.

The installer will automatically add `vagrant` to your system path
so that it is available in terminals. If it is not found, please try
logging out and logging back in to your system (this is particularly
necessary sometimes for Windows).

<div class="alert alert-warning" role="alert">
  <strong>Looking for the gem install?</strong> Vagrant 1.0.x had the option to
  be installed as a <a href="https://en.wikipedia.org/wiki/RubyGems">RubyGem</a>.
  This installation method is no longer supported. If you have an old version
  of Vagrant installed via Rubygems, please remove it prior to installing newer
  versions of Vagrant.
</div>

<div class="alert alert-warning" role="alert">
  <strong>Beware of system package managers!</strong> Some operating system
  distributions include a vagrant package in their upstream package repos.
  Please do not install Vagrant in this manner. Typically these packages are
  missing dependencies or include very outdated versions of Vagrant. If you
  install via your system's package manager, it is very likely that you will
  experience issues. Please use the official installers on the downloads page.
</div>
