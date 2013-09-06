---
page_title: "Installation - VMware Provider"
sidebar_current: "vmware-installation"
---

# Installation

The VMware provider is installed using
[standard plugin installation procedures](/v2/plugins/usage.html).
In addition to installing the plugin, a license must be provided so that
it can be loaded properly.

To purchase a license, visit the [Vagrant VMware provider](http://www.vagrantup.com/vmware)
page. After purchasing a license, a link to download it will be emailed
to you. Download this file.

Installing the plugin and license is easy using the `vagrant plugin`
interface. Both steps are shown below. Note that the plugin name is different
depending on the provider you're using. If you're using the Fusion provider,
it is `vagrant-vmware-fusion`. If you're using the Workstation provider,
it is `vagrant-vmware-workstation`.

```
$ vagrant plugin install vagrant-vmware-fusion
...
$ vagrant plugin license vagrant-vmware-fusion license.lic
...
```

For licensing, the first parameter is the name of the plugin, which is
`vagrant-vmware-fusion` for the VMware Fusion provider, or `vagrant-vmware-workstation`
for the VMware Workstation provider. The second parameter is the path to the license itself.

You can verify the license is properly installed by running any
Vagrant command, such as `vagrant plugin list`. The VMware
provider will show an error message if you are missing a license or using an
invalid license.

If there are problems installing the plugin, please contact
[support](http://www.vagrantup.com/support.html).
