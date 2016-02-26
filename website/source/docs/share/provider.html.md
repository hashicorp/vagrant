---
layout: "docs"
page_title: "Custom Provider - Vagrant Share"
sidebar_current: "share-provider"
description: |-
  If you are developing a custom Vagrant provider, you will need to do a tiny
  bit more work in order for it to work well with Vagrant Share.
---

# Custom Provider

<div class="alert alert-warning">
  <strong>Warning: Advanced Topic!</strong> This topic is related to
  developing Vagrant plugins. If you are not interested in this or
  you are just starting with Vagrant, it is safe to skip this page.
</div>

If you are developing a [custom Vagrant provider](/docs/plugins/providers.html),
you will need to do a tiny bit more work in order for it to work well with
Vagrant Share.

For now, this is only one step:

  * `public_address` provider capability - You must implement this capability
  to return a string that is an address that can be used to access the
  guest from Vagrant. This does not need to be a globally routable address,
  it only needs to be accessible from the machine running Vagrant. If you
  cannot detect an address, return `nil`.
