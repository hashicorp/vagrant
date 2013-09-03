---
sidebar_current: "vmware-known-issues"
---

# Known Issues

This page tracks some known issues or limitations of the VMware providers.
Note that none of these are generally blockers to using the provider, but
are good to know.

## vmnet Device Cleanup

When creating a private network with VMware, the Vagrant provider will
create a new `vmnet` device for your IP/subnet if one doesn't already exist.
Vagrant currently never cleans up unused `vmnet` devices. This must be
done manually via the VMware network editor.

In practice, this is not an issue because there are really only
[three IPv4 address spaces](http://en.wikipedia.org/wiki/Private_network#Private_IPv4_address_spaces)
that can be used for these networks, so not many extraneous vmnet devices
are left lying around.

However, if you use automatically generated IP addresses that use many
subnets, you may find that there are many extra vmnet devices. Manually
remove these for now. A future release of the provider will address this
limitation in some way.

## Forwarded Ports Failing in Workstation on Windows

VMware Workstation has a bug on Windows where forwarded ports don't work
properly. Vagrant actually works around this bug and makes them work. However,
if you run the virtual network editor on Windows, the forwarded ports will
suddenly stop working.

In this case, run `vagrant reload` and things will begin working again.

This issue has been reported to VMware, but a fix hasn't been released yet.
