---
page_title: "Usage - VMware Provider"
sidebar_current: "vmware-usage"
---

# Usage

The Vagrant VMware providers are used just like any other provider. Please
read the general [basic usage](/v2/providers/basic_usage.html) page for
providers.

The value to use for the `--provider` flag is `vmware_fusion` for VMware
Fusion, and `vmware_workstation` for VMware Workstation.

The Vagrant VMware provider does not support parallel execution at this time.
Specifying the `--parallel` option will have no effect.

<p>
To get started, a 64-bit Ubuntu 12.04 LTS VMware box is available at:
<a href="http://files.vagrantup.com/precise64_vmware.box">http://files.vagrantup.com/precise64_vmware.box</a>
</p>

<div class="alert alert-info">
	<p>
		<strong>Note:</strong> At some point in the future, the providers
		will probably be merged into a single `vagrant-vmware` plugin. For now,
		the Workstation and Fusion codebases are different enough that they
		are separate plugins.
	</p>
</div>
