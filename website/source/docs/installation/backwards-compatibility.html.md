---
layout: "docs"
page_title: "Backwards Compatibility"
sidebar_current: "installation-backwards-compatibility"
description: |-
  Vagrant makes a very strict backwards-compatability promise.
---

# Backwards Compatibility

## For 1.0.x

Vagrant 1.1+ provides full backwards compatibility for valid Vagrant 1.0.x
Vagrantfiles which do not use plugins. After installing Vagrant 1.1, your 1.0.x
environments should continue working without modifications, and existing running
machines will continue to be managed properly.

This compatibility layer will remain in Vagrant up to and including Vagrant 2.0.
It may still exist after that, but Vagrant's compatibility promise is only for
two versions. Seeing that major Vagrant releases take years to develop and
release, it is safe to stick with your version 1.0.x Vagrantfile for the
time being.

If you use any Vagrant 1.0.x plugins, you must remove references to these from
your Vagrantfile prior to upgrading. Vagrant 1.1+ introduces a new plugin
format that will protect against this sort of incompatibility from ever
happening again.

## For 1.x

Backwards compatibility between 1.x is not promised, and Vagrantfile
syntax stability is not promised until 2.0 final. Any backwards
incompatibilities within 1.x will be clearly documented.

This is similar to how Vagrant 0.x was handled. In practice, Vagrant 0.x
only introduced a handful of backwards incompatibilities during the entire
development cycle, but the possibility of backwards incompatibilities
is made clear so people are not surprised.

Vagrant 2.0 final will have a stable Vagrantfile format that will
remain backwards compatible, just as 1.0 is considered stable.
