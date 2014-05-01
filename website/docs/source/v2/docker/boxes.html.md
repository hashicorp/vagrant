---
page_title: "Boxes - Docker Provider"
sidebar_current: "docker-boxes"
---

# Docker Boxes

The Docker provider doesn't require a Vagrant box. The `config.vm.box`
setting is completely optional.

A box can still be used and specified, however, to provide defaults.
Because the `Vagrantfile` within a box is loaded as part of the
configuration loading sequence, it can be used to configure the
foundation of a development environment.

In general, however, you won't need a box with the Docker provider.
