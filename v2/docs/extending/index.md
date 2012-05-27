---
layout: extending
title: Extending Vagrant - Overview

current: Overview
---
# Extending Vagrant

It is often necessary to extend the tools you use to tailor it specifically
to your needs. Vagrant exposes an API which allows developers to hook into
almost every imaginable part to do whatever you want. This section will guide
you through the basics of plugin creation as well as touch upon just enough
of the Vagrant internals so that you are comfortable working on a plugin.

## Why Extend Vagrant?

Vagrant comes with a ton of features out of the box, and perhaps you've
been satisfied with this. But there are many feature requests out there
which either don't make sense for the core of Vagrant, or are highly
specialized use cases you'd like to incorporate into the tool for your
team.

Using plugins, you can do any of the following things (and much more):

* Modify `/etc/hosts` during `vagrant up` to add aliases for host
  only networks.
* Add custom commands to `vagrant` such as `vagrant run-tests` which
  might run the tests in the VM.
* Add a new configuration option that modifies how Vagrant behaves.
