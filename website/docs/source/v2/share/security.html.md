---
page_title: "Security - Vagrant Share"
sidebar_current: "share-security"
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

  * `--ssh-once` will allow only one person to SSH into your shared environment.
    After the first SSH access, the keypair is physically deleted and SSH
    access won't be possible anymore.

In addition to these options, there are other features we've built to help:

  * Vagrant share uses end-to-end TLS connections. So even unencrypted TCP streams
    are encrypted through the various proxies and only unencrypted during the final
    local communication between the local proxy and the Vagrant environment.

  * Share names, such as happy-panda-1234, are randomly chosen from a pool
    of over 40,000,000 possible names. And we're routinely adding more
    words to grow this pool. It is unlikely that anyone will guess your
    share name.

  * SSH keys are encrypted by default, using a password that is not transmitted
    to our servers or across the network at all.

  * SSH is not shared by default, it must explicitly be shared with the
    `--ssh` flag.

  * A web interface we've built shows share history and will show basic
    access logs in the future.

  * Share sessions expire after a short time (currently 1 hour), but
    can also be expired manually by `ctrl-c` from the sharing machine
    or via the web interface.

Most importantly, you must understand that by running `vagrant share`,
you are making your Vagrant environment accessible by anyone who knows
the share name. When share is not running, it is not accessible.

Later, we will be expanding the security of this feature by adding ACLs,
so you're able to explicitly allow
access to your share based on who is connecting.

For maximum security, we will also allow you to run your own Vagrant
Share server. This option isn't available yet.
