---
layout: "docs"
page_title: "Usage - Hyper-V Provider"
sidebar_current: "providers-hyperv-usage"
description: |-
  The Hyper-V provider is used just like any other provider. Please read the
  general basic usage page for providers.
---

# Usage

The Vagrant Hyper-V provider is used just like any other provider. Please
read the general [basic usage](/docs/providers/basic_usage.html) page for
providers.

The value to use for the `--provider` flag is `hyperv`.

Hyper-V also requires that you execute Vagrant with administrative
privileges. Creating and managing virtual machines with Hyper-V requires
admin rights. Vagrant will show you an error if it does not have the proper
permissions.

Boxes for Hyper-V can be easily found on
[HashiCorp's Vagrant Cloud](https://vagrantcloud.com/boxes/search). To get started, you might
want to try the `hashicorp/precise64` box.
