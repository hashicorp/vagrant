---
layout: "docs"
page_title: "Boxes - Docker Provider"
sidebar_current: "providers-docker-boxes"
description: |-
  The Docker provider does not require a Vagrant box. The "config.vm.box"
  setting is completely optional.
---

# Docker Boxes

The Docker provider does not require a Vagrant box. The `config.vm.box`
setting is completely optional.

A box can still be used and specified, however, to provide defaults.
Because the `Vagrantfile` within a box is loaded as part of the
configuration loading sequence, it can be used to configure the
foundation of a development environment.

In general, however, you will not need a box with the Docker provider.
