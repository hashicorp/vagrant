---
layout: "docs"
page_title: "vagrant share - Command-Line Interface"
sidebar_current: "cli-share"
description: |-
  The "vagrant share" command initializes a new Vagrant share session, which
  allows you to share your virtual machine with the public Internet.
---

# Share

**Command: `vagrant share`**

The share command initializes a Vagrant Share session, allowing you to
share your Vagrant environment with anyone in the world, enabling collaboration
directly in your Vagrant environment in almost any network environment.

You can learn about all the details of Vagrant Share in the
[Vagrant Share section](/docs/share/).

The reference of available command-line flags to this command
is available below.

## Options

* `--disable-http` - Disables the creation of a publicly accessible
  HTTP endpoint to your Vagrant environment. With this set, the only way
  to access your share is with `vagrant connect`.

* `--http PORT` - The port of the HTTP server running in the Vagrant
  environment. By default, Vagrant will attempt to find this for you.
  This has no effect if `--disable-http` is set.

* `--https PORT` - The port of an HTTPS server running in the Vagrant
  environment. By default, Vagrant will attempt to find this for you.
  This has no effect if `--disable-http` is set.

* `--ssh` - Enables SSH sharing (more information below). By default, this
  is not enabled.

* `--ssh-no-password` - Disables the encryption of the SSH keypair created
  when SSH sharing is enabled.

* `--ssh-port PORT` - The port of the SSH server running in the Vagrant
  environment. By default, Vagrant will attempt to find this for you.

* `--ssh-once` - Allows SSH access only once. After the first attempt to
  connect via SSH to the Vagrant environment, the generated keypair is
  destroyed.
