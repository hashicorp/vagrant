---
layout: "docs"
page_title: "Usage - VirtualBox Provider"
sidebar_current: "providers-virtualbox-usage"
description: |-
  The Vagrant VirtualBox provider is used just like any other provider. Please
  read the general basic usage page for providers.
---

# Usage

The Vagrant VirtualBox provider is used just like any other provider. Please
read the general [basic usage](/docs/providers/basic_usage.html) page for
providers.

The value to use for the `--provider` flag is `virtualbox`.

The Vagrant VirtualBox provider does not support parallel execution at this
time. Specifying the `--parallel` option will have no effect.
