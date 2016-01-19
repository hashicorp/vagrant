---
layout: "docs"
page_title: "Known Issues - VMware Provider"
sidebar_current: "providers-vmware-known-issues"
description: |-
  This page tracks some known issues or limitations of the VMware providers.
  Note that none of these are generally blockers to using the provider, but
  are good to know.
---

# Known Issues

This page tracks some known issues or limitations of the VMware providers.
Note that none of these are generally blockers to using the provider, but
are good to know.

## Forwarded Ports Failing in Workstation on Windows

VMware Workstation has a bug on Windows where forwarded ports do not work
properly. Vagrant actually works around this bug and makes them work. However,
if you run the virtual network editor on Windows, the forwarded ports will
suddenly stop working.

In this case, run `vagrant reload` and things will begin working again.

This issue has been reported to VMware, but a fix has not been released yet.
