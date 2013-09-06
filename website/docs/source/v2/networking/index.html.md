---
page_title: "Networking"
sidebar_current: "networking"
---

# Networking

In order to access the Vagrant environment created, Vagrant exposes
some high-level networking options for things such as forwarded ports,
connecting to a public network, or creating a private network.

The high-level networking options are meant to define an abstraction that
works across multiple [providers](/v2/providers/index.html). This means that
you can take your Vagrantfile you used to spin up a VirtualBox machine and
you can reasonably expect that Vagrantfile to behave the same with something
like VMware.

You should first read the [basic usage](/v2/networking/basic_usage.html) page
and then continue by reading the documentation for a specific networking
primitive by following the navigation to the left.

## Advanced Configuration

In some cases,
these options are _too_ high-level, and you may want to more finely tune
and configure the network interfaces of the underlying machine. Most
providers expose [provider-specific configuration](/v2/providers/configuration.html)
to do this, so please read the documentation for your specific provider
to see what options are available.

<div class="alert alert-info">
	<p>
		<strong>For beginners:</strong> It is strongly recommended you use
		only the high-level networking options until you are comfortable
		with the Vagrant workflow and have things working at a basic level.
		Provider-specific network configuration can very quickly lock you out
		of your guest machine if improperly done.
	</p>
</div>

