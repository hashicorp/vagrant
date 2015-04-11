---
page_title: "Vagrant Connect - Vagrant Share"
sidebar_current: "share-connect"
---

# Vagrant Connect

Vagrant can share any or _every_ port to your Vagrant environment, not
just SSH and HTTP. The `vagrant connect` command gives the connecting person
a static IP they can use to communicate to the shared Vagrant environment.
Any TCP traffic sent to this IP is sent to the shared Vagrant environment.

## Usage

Just call `vagrant share`. This will automatically share as many ports as
possible for remote connections. If the Vagrant environment has a static IP or DNS address, then every port
will be available. Otherwise, Vagrant will only expose forwarded ports on
the machine.

Note the share name at the end of calling `vagrant share`, and give this to
the person who wants to connect to your machine. They simply have to call
`vagrant connect NAME`. This will give them a static IP they can use to access
your Vagrant environment.

## How does it work?

`vagrant connect` works by doing what Vagrant does best: managing virtual
machines. `vagrant connect` creates a tiny virtual machine that takes up
only around 20 MB in RAM, using VirtualBox or VMware (more provider support
is coming soon).

Any traffic sent to this tiny virtual machine is then proxied through to
the shared Vagrant environment as if it were directed at it.

## Beware: Vagrant Insecure Key

If the Vagrant environment or box you're using is protected with the
Vagrant insecure keypair (most public boxes are), then SSH will be easily
available to anyone who connects.

While hopefully you're sharing with someone you trust, in certain environments
you might be sharing with a class, or a conference, and you don't want them
to be able to SSH in.

In this case, we recommend changing or removing the insecure key from
the Vagrant machine.

Finally, we want to note that we are working on making it so that when
Vagrant share is used, the Vagrant private key is actively rejected unless
explicitly allowed. This feature is not yet done, however.
