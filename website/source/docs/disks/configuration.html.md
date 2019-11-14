---
layout: "docs"
page_title: "Vagrant Disks Configuration"
sidebar_current: "disks-configuration"
description: |-
  Documentation of various configuration options for Vagrant Disks
---

# Configuration

Vagrant Disks has several options that allow users to define and attach disks to guests.

## Disk Options

* `name` (string) - Optional argument to give the disk a name
* `type` (symbol) - The type of disk to manage. This option defaults to `:disk`. Please read the provider specific documentation for supported types.
* `file` (string) - Optional argument that defines a path on disk pointing to the location of a disk file.
* `primary` (boolean) - Optional argument that configures a given disk to be the "primary" disk to manage on the guest. There can only be one `primary` disk per guest.
* `provider_config` (hash) - Additional provider specific options for managing a given disk.

    Generally, the disk option accepts two kinds of ways to define a provider config:

    + `providername__diskoption = value`
      - The provider name followed by a double underscore, and then the provider specific option for that disk
    + `{providername: {diskoption: value}, otherprovidername: {diskoption: value}`
      - A hash where the top level key(s) are one or more providers, and each provider keys values are a hash of options and their values.

    **Note:** More specific examples of these can be found under the provider specific disk page. The `provider_config` option will depend on the provider you are using. Please read the provider specific documentation for disk management to learn about what options are available to use.

## Disk Types

## Provider Author Guide

If you are a vagrant plugin author who maintains a provider for Vagrant, this short guide will hopefully give some information on how to use the internal disk config object.
