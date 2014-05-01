---
page_title: "Vagrant 1.5 Feature Preview: Vagrant Share"
title: "Feature Preview: Vagrant Share"
author: Jack Pearkes
author_url: https://github.com/pearkes
---

A primary goal of Vagrant is not only to provide easy-to-use development
environments, but also to make it easy to share and collaborate on
these environments.

With Vagrant 1.5, we're introducing a feature that will allow you to share
your running Vagrant environment with anyone, on any network connected
to the internet. We're calling this feature 'Vagrant Share.'

This feature lets you share a link to your web server to a teammate across
the country, or just across the office. It'll feel like they're accessing
a normal website, but actually they'll be talking directly to your running
Vagrant environment. They'll be able to see any changes you make, as you make
them, in real time.

With Vagrant Share, others can not only access your web server, they
can access your Vagrant environment like it was any other machine on a
local network. They can have access to any and every port.

Read on for a demo and more details.

READMORE

### Demo

Before we get into details about Vagrant share, let's show a few demos.
You may need to go fullscreen to read the text.

Sharing an HTTP server:

<iframe src="//player.vimeo.com/video/87525972" width="770" height="394" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

Sharing SSH access:

<iframe src="//player.vimeo.com/video/87525810" width="770" height="394" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

Sharing a static IP with Vagrant Connect:

<iframe src="//player.vimeo.com/video/87590529" width="770" height="394" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>


### Vagrant Share, Vagrant Connect

The feature we call "Vagrant Share" introduces two new Vagrant commands:
`vagrant share` and `vagrant connect`.

The `share` command is used to share a running Vagrant environment, and
the `connect` command compliments it by accessing any shared environment.
Note that if you're just sharing HTTP access, the accessing party does
_not_ need Vagrant installed. This is covered later.

We'll cover the details of each command next.

### HTTP Sharing

By default, Vagrant Share shares HTTP access to your Vagrant environment
to anyone in the world. The URL that it creates is publicly accessible
and doesn't require Vagrant to be installed to access -- just a web browser.

```
$ vagrant share
==> default: Local HTTP port: 5000
    default: Local HTTPS port: disabled
==> default: Your Vagrant Share is running!
==> default: URL: http://frosty-weasel-0857.vagrantshare.com
...
```

Once the share is created, a relatively obscure URL is outputted. This URL
will route directly to your Vagrant environment; it doesn't matter if you
or accessing party is behind a firewall or NAT.

Currently, HTTP access is restricted through obscure URLs. We'll be adding
more ACLs and audit logs for this in the future.

### SSH Access

While sharing your local webserver is a powerful collaboration tool,
Vagrant Share doesn't stop there. With just a single flag, Vagrant Share
can allow anyone to easily SSH into your Vagrant environment.

Perhaps you're having issues where your app isn't running properly or you
just want to pair program. Now, with just one flag, anyone you want can
SSH into your Vagrant environment from anywhere in the world.

SSH access isn't shared by default. To enable sharing SSH, you must add
the `--ssh` flag to `vagrant share`:

```
$ vagrant share --ssh
==> default: SSH Port: 22
==> default: Generating new SSH key...
    default: Please enter a password to encrypt the key:
    default: Repeat the password to confirm:
    default: Inserting generated SSH key into machine...
==> default: Checking authentication and authorization...
==> default: Creating Vagrant Share session...
    default: Share will be at: awful-squirrel-9454
==> default: Your Vagrant Share is running!
...
```

When the `--ssh` flag is provided, Vagrant generates a brand new SSH keypair
for SSH access. The public key portion is automatically inserted into the
Vagrant environment. The private key portion is uploaded to the server
managing the Vagrant Share connections. The password used to encrypt the
private key is _not_ uploaded anywhere, however, meaning we couldn't access
your VM if we wanted to. It is an extra layer of security.

Once SSH access is shared, the person wanting to access your Vagrant
environment uses `vagrant connect` to SSH in:

```
$ vagrant connect --ssh awful-squirrel-9454
Loading share 'awful-squirrel-9454'...
Password for the private key:
Executing SSH...

Welcome to Ubuntu 12.04.1 LTS

 * Documentation:  https://help.ubuntu.com/
Last login: Wed Feb 26 08:38:55 2014 from 192.168.148.1
vagrant@precise64:/vagrant$
```

The name of the share and the password used to encrypt the private key
must be communicated to the other person manually, as a security measure.

### Vagrant Connect

Vagrant share can share any TCP/UDP connection, and is not restricted
to only a single port. When you run `vagrant share`, Vagrant will share
the entire Vagrant environment.

When the person you are sharing with runs `vagrant connect SHARE-NAME`,
Vagrant will give this person a static IP they can use to access the
machine as if it were on the local network:

```
$ vagrant connect awful-squirrel-9454
==> connect: Connecting to: awful-squirrel-9454
==> connect: Starting a VM for a static connect IP.
    connect: The machine is booted and ready!
==> connect: Connect is running!
==> connect: SOCKS address: 127.0.0.1:62167
==> connect: Machine IP: 172.16.0.2
==> connect:
==> connect: Press Ctrl-C to stop connection.
...
```

### Security Concerns

Sharing your Vagrant environment understandably raises a number of security
issues.

With the launch of Vagrant 1.5, the primary security mechanism for Vagrant
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

And, after Vagrant 1.5 is released, we will be expanding the security
of this feature by adding ACLs, so you're able to explicitly allow
access to your share based on who is connecting.

For maximum security, we will allow you to run your own Vagrant
Share server. We won't be launching this right with Vagrant 1.5, but it
will be an option shortly after that.

### Technical Details

We've been demoing Vagrant Share around the world over the past month
or so. The response has been overwhelmingly positive, but the first reaction
from everyone is always: "How does this work?" In this section, we'll briefly
cover some technical details of the feature.

There are a lot of moving parts that make Vagrant Share work. Here is
an overview of the primary components:

  * **Local Proxy** - This runs on the share host machine (_not_ within the
   Vagrant environment). It connects to the remote proxy and proxies traffic
   to and from the Vagrant environment and the remote proxy. It is also
   responsible for registering new shares with the remote proxy.

  * **Remote Proxy** - This runs on a remote server on the internet. It
   creates shares and is connected to local proxies. It also handles all ACLs,
   security audit logs, SSH keys, and more.

  * **Connect Proxy VM** - When `vagrant connect` is called, Vagrant runs
   a very small proxy virtual machine (13 MB RAM-only!). This virtual machine
   exposes the static IP that the connecting person uses to access the share.
   Any traffic sent to this IP is routed to the remote proxy, which in turn
   routes down to the local proxy and the shared Vagrant environment.

The connection from the connect proxy to the remote proxy uses the standard
[SOCKS5 protocol](http://en.wikipedia.org/wiki/SOCKS). The connection between
the remote proxy and the local proxy uses a modified variant to reduce the
number of packets that must be sent for any given connection.

### What's Next?

Vagrant Share will ship with Vagrant 1.5. To use it, you'll need an
account in the yet to be announced web service.

At that time, we'll publish further details about share, connect
and the account required to use them.

Next week, we'll cover another feature of Vagrant 1.5 &mdash; stay tuned.
