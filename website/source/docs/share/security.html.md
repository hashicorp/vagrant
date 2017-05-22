---
layout: "docs"
page_title: "Security - Vagrant Share"
sidebar_current: "share-security"
description: |-
  Sharing your Vagrant environment understandably raises a number of security
  concerns.
---

# Security

Sharing your Vagrant environment understandably raises a number of security
concerns.

The primary security mechanism for Vagrant
Share is security through obscurity along with an encryption key for SSH.
Additionally, there are several configuration options made available to
help control access and manage security:

  * `--disable-http` will not create a publicly accessible HTTP URL. When
    this is set, the only way to access the share is with `vagrant connect`.

In addition to these options, there are other features we've built to help:

  * Vagrant share uses end-to-end TLS for non-HTTP connections. So even unencrypted
    TCP streams are encrypted through the various proxies and only unencrypted during
    the final local communication between the local proxy and the Vagrant environment.

  * SSH keys are encrypted by default, using a password that is not transmitted
    to our servers or across the network at all.

  * SSH is not shared by default, it must explicitly be shared with the
    `--ssh` flag.

Most importantly, you must understand that by running `vagrant share`,
you are making your Vagrant environment accessible by anyone who knows
the share name. When share is not running, it is not accessible.
