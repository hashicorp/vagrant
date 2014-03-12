---
page_title: "Custom Provider - Vagrant Share"
sidebar_current: "share-provider"
---

# Custom Provider

<div class="alert alert-warn">
	<p>
		<strong>Warning: Advanced Topic!</strong> This topic is related to
		developing Vagrant plugins. If you're not interested in this or
		you're just starting with Vagrant, it is safe to skip this page.
	</p>
</div>

If you're developing a [custom provider](/v2/plugins/providers.html), you'll
need to do a tiny bit more work in order for it to work well with Vagrant
Share.

For now, this is only one step:

  * `public_address` provider capability - You must implement this capability
	to return a string that is an address that can be used to access the
	guest from Vagrant. This does not need to be a globally routable address,
	it only needs to be accessible from the machine running Vagrant. If you
	can't detect an address, return `nil`.
