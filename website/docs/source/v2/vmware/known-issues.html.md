---
page_title: "Known Issues - VMware Provider"
sidebar_current: "vmware-known-issues"
---

# Known Issues

This page tracks some known issues or limitations of the VMware providers.
Note that none of these are generally blockers to using the provider, but
are good to know.

## Forwarded Ports Failing in Workstation on Windows

VMware Workstation has a bug on Windows where forwarded ports don't work
properly. Vagrant actually works around this bug and makes them work. However,
if you run the virtual network editor on Windows, the forwarded ports will
suddenly stop working.

In this case, run `vagrant reload` and things will begin working again.

This issue has been reported to VMware, but a fix hasn't been released yet.
