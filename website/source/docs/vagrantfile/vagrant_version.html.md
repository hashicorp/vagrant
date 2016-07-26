---
layout: "docs"
page_title: "Minimum Vagrant Version - Vagrantfile"
sidebar_current: "vagrantfile-minversion"
description: |-
  A set of Vagrant version requirements can be specified in the Vagrantfile
  to enforce that people use a specific version of Vagrant with a Vagrantfile.
  This can help with compatibility issues that may otherwise arise from using
  a too old or too new Vagrant version with a Vagrantfile.
---

# Minimum Vagrant Version

A set of Vagrant version requirements can be specified in the Vagrantfile
to enforce that people use a specific version of Vagrant with a Vagrantfile.
This can help with compatibility issues that may otherwise arise from using
a too old or too new Vagrant version with a Vagrantfile.

Vagrant version requirements should be specified at the top of a Vagrantfile
with the `Vagrant.require_version` helper:

```ruby
Vagrant.require_version ">= 1.3.5"
```

In the case above, the Vagrantfile will only load if the version loading it
is Vagrant 1.3.5 or greater.

Multiple requirements can be specified as well:

```ruby
Vagrant.require_version ">= 1.3.5", "< 1.4.0"
```
