---
layout: "docs"
page_title: "Providers"
sidebar_current: "providers"
description: |-
  While Vagrant ships out of the box with support for VirtualBox, Hyper-V, and
  Docker. Vagrant has the ability to manage other types of machines as well.
  This is done by using other providers with Vagrant.
---

# Providers

While Vagrant ships out of the box with support for [VirtualBox](https://www.virtualbox.org),
[Hyper-V](https://www.microsoft.com/hyper-v), and [Docker](https://www.docker.io),
Vagrant has the ability to manage other types of machines as well. This is done
by using other _providers_ with Vagrant.

Alternate providers can offer different features that make more sense in your use case.
For example, if you are using Vagrant for any real work, [VMware](https://www.vmware.com)
providers are recommended since they're well supported and generally more
stable and performant than VirtualBox.

Before you can use another provider, you must install it. Installation of other providers
is done via the Vagrant plugin system.

Once the provider is installed, usage is straightforward and simple, as
you would expect with Vagrant. Read into the relevant subsections found in
the navigation to the left for more information.
