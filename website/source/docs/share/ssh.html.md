---
layout: "docs"
page_title: "SSH Sharing - Vagrant Share"
sidebar_current: "share-ssh"
description: |-
  Vagrant share makes it trivially easy to allow remote SSH access to your
  Vagrant environment by supplying the "--ssh" flag to "vagrant share".
---

# SSH Sharing

Vagrant share makes it trivially easy to allow remote SSH access to your
Vagrant environment by supplying the `--ssh` flag to `vagrant share`.

Easy SSH sharing is incredibly useful if you want to give access to
a colleague for troubleshooting ops issues. Additionally, it enables
pair programming with a Vagrant environment, if you want!

SSH sharing is disabled by default as a security measure. To enable
SSH sharing, simply supply the `--ssh` flag when calling `vagrant share`.

## Usage

Just run `vagrant share --ssh`!

When SSH sharing is enabled, Vagrant generates a brand new keypair for
SSH access. The public key portion is automatically inserted
into the Vagrant machine, and the private key portion is provided to the
user connecting to the Vagrant share. This private key is encrypted using
a password that you will be prompted for. This password is _never_ transmitted
across the network by Vagrant, and is an extra layer of security preventing
anyone who may know your share name from easily accessing your machine.

After running `vagrant share --ssh`, it will output the name of your share:

```
$ vagrant share --ssh
==> default: Detecting network information for machine...
default: Local machine address: 192.168.84.130
==> default: Generating new SSH key...
default: Please enter a password to encrypt the key:
default: Repeat the password to confirm:
default: Inserting generated SSH key into machine...
default: Local HTTP port: disabled
default: Local HTTPS port: disabled
default: SSH Port: 2200
==> default: Creating Vagrant Share session...
share: Cloning VMware VM: 'hashicorp/vagrant-share'. This can take some time...
share: Verifying vmnet devices are healthy...
share: Preparing network adapters...
share: Starting the VMware VM...
share: Waiting for machine to boot. This may take a few minutes...
share: SSH address: 192.168.84.134:22
share: SSH username: tc
share: SSH auth method: password
share:
share: Inserting generated public key within guest...
share: Removing insecure key from the guest if it's present...
share: Key inserted! Disconnecting and reconnecting using new SSH key...
share: Machine booted and ready!
share: Forwarding ports...
share: -- 31338 => 65534
share: -- 22 => 2202
share: SSH address: 192.168.84.134:22
share: SSH username: tc
share: SSH auth method: password
share: Configuring network adapters within the VM...
==> share:
==> share: Your Vagrant Share is running! Name: bazaar_wolf:sultan_oasis
==> share:
==> share: You're sharing with SSH access. This means that another can SSH to
==> share: your Vagrant machine by running:
==> share:
==> share:   vagrant connect --ssh bazaar_wolf:sultan_oasis
==> share:
```

Anyone can then SSH directly to your Vagrant environment by running
`vagrant connect --ssh NAME` where NAME is the name of the share outputted
previously.

```
$ vagrant connect --ssh bazaar_wolf:sultan_oasis
Loading share 'bazaar_wolf:sultan_oasis'...
The SSH key to connect to this share is encrypted. You will
require the password entered when creating the share to
decrypt it. Verify you have access to this password before
continuing.

Press enter to continue, or Ctrl-C to exit now.
Password for the private key:
Executing SSH...
Welcome to Ubuntu 12.04.3 LTS (GNU/Linux 3.8.0-29-generic x86_64)

 * Documentation:  https://help.ubuntu.com/
Last login: Fri Mar  7 17:44:50 2014 from 192.168.163.1
vagrant@vagrant:~$
```

If the private key is encrypted (the default behavior), then the connecting
person will be prompted for the password to decrypt the private key.
