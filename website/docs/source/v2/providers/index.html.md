---
page_title: "Providers"
sidebar_current: "providers"
---

# Providers

While Vagrant is mostly known for its [VirtualBox](http://www.virtualbox.org),
Vagrant has the ability to manage other types of machines as well. This is done
by using other _providers_ with Vagrant.

Alternate providers can offer different features that make more sense in your use case.
For example, if you're using Vagrant for any real work, [VMware](http://www.vmware.com)
providers are recommended since they're well supported and generally more
stable and performant than VirtualBox.

Vagrant ships with VirtualBox, [Docker](https://www.docker.com/) and [Hyper-V](https://en.wikipedia.org/wiki/Hyper-V)
support but other providers are also supported by leveraging the Vagrant plugin system.
Before you can use another provider, you must install it.

Once the provider is installed, usage is straightforward and simple, as
you would expect with Vagrant. Read into the relevant subsections found in
the navigation to the left for more information.
