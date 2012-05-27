---
layout: default
title: Versioning Scheme
---

<h1 class="top">Versioning Scheme</h1>

Vagrant versions are quite easy to follow, and follow a predictable set of
rules so that users of Vagrant know what they're getting into whenever there
may be a new version. This page is not an exhaustive set of rules for
the versioning scheme, but covers the major points. Vagrant versions can
quickly be identified as part of either a **stable release**, or part of
an **experimental series**.

## Stable Release

**Stable** versions of Vagrant are in the form X.0.Z, where X is the
major stable version ("version 1" or "version 2"), and Z represents simple
bug fixes. Bug fixes never introduce backwards incompatibilities with the
stable version.

Stable release attributes:

* Slow-moving. New features are not introduced.
* A change in the Z version is only done for bug fixes, and never introduce
  backwards incompatibilities.
* Vagrantfile is meant to be compatible with future stable versions. Therefore,
  a Vagrantfile for 1.0 should work with no modifications with version 2.0.
* The documentation linked from the [Vagrant homepage](/) always links to the
  stable release documentation.

## Experimental Releases

**Experimental** versions of Vagrant are in the form X.Y.Z, where Y > 0. This
represents a series of experimental releases that eventually lead to a major
stable version. For example, the "1.x" series includes 1.1, 1.2, 1.3, etc.
and will eventually lead to a stable version 2.0 of Vagrant.

Experimental release attributes:

* Contain new features which may be unstable, although historically are
  fairly well tested by release.
* Backward incompatibilities can be introduced at any point, but are
  generally well documented in the CHANGELOG.
* May break the backwards compatibility promise of prior stable release
  Vagrantfiles, but this is fixed prior to any stable release.

Experimental releases are generally quite stable, and should be used if you're
interested in trying the latest features of Vagrant. Vagrant 1.0 was "experimental" for
two years before becoming a stable release, so "experimental" doesn't mean
"unstable."
