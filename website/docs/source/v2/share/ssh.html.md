---
page_title: "SSH Sharing - Vagrant Share"
sidebar_current: "share-ssh"
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
into the Vagrant machine, and the private key portion is uploaded to the
server managing the Vagrant shares. This private key is encrypted using
a password that you will be prompted for. This password is _never_ transmitted
across the network by Vagrant, and is an extra layer of security preventing
us or anyone who may know your share name from easily accessing your machine.

After running `vagrant share --ssh`, it will output the name of your share:

```
$ vagrant share --ssh
==> default: Detecting network information for machine...
    default: Local machine address: 192.168.163.152
    default: Local HTTP port: 4567
    default: Local HTTPS port: disabled
    default: SSH Port: 22
==> default: Generating new SSH key...
    default: Please enter a password to encrypt the key:
    default: Repeat the password to confirm:
    default: Inserting generated SSH key into machine...
==> default: Checking authentication and authorization...
==> default: Creating Vagrant Share session...
    default: Share will be at: itty-bitty-polar-8667
==> default: Your Vagrant Share is running!
    default: Name: itty-bitty-polar-8667
...
```

Anyone can then SSH directly to your Vagrant environment by running
`vagrant connect --ssh NAME` where NAME is the name of the share outputted
previously.

```
$ vagrant connect --ssh itty-bitty-polar-8667
Loading share 'itty-bitty-polar-8667'...
The SSH key to connect to this share is encrypted. You will
require the password entered when creating to share to
decrypt it. Verify you access to this password before
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

Additional flags are available such as `--ssh-once` to add another layer
of security to your SSH shared session. With this flag active, only one
`vagrant connect --ssh` can be attempted before the keypair is destroyed,
preventing any future connections.
