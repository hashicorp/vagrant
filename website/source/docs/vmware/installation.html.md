---
layout: "docs"
page_title: "Installation - VMware Provider"
sidebar_current: "providers-vmware-installation"
description: |-
  The Vagrant VMware provider can be installed using the standard plugin
  installation procedure.
---

# Installation

If you are upgrading from the Vagrant VMware Workstation or Vagrant
VMware Fusion plugins, please halt or destroy all VMware VMs currently
being managed by Vagrant. Then continue with the instructions below.

Installation of the Vagrant VMware provider requires two steps. First the
Vagrant VMware Utility must be installed. This can be done by downloading
and installing the correct system package from the [Vagrant VMware Utility
downloads page](/vmware/downloads.html).

Next, install the Vagrant VMware provider plugin using the standard plugin
installation procedure:

```shell
$ vagrant plugin install vagrant-vmware-desktop
```

For more information on plugin installation, please see the
[Vagrant plugin usage documentation](/docs/plugins/usage.html).

The Vagrant VMware plugin is a commercial product provided by
[HashiCorp](https://www.hashicorp.com) and **require the purchase of a license**
to operate. To purchase a license, please visit the
[Vagrant VMware provider](/vmware#buy-now) page. Upon
purchasing a license, you will receive a license file in your inbox. Download
this file and save it to a temporary location on your computer.

<div class="alert alert-warning">
  <strong>Warning!</strong> You cannot use your VMware product license as a
  Vagrant VMware plugin license. They are separate commercial products, each
  requiring their own license.
</div>

After installing the Vagrant VMware Desktop plugin for your system, you
will need to install the license:

```shell
$ vagrant plugin license vagrant-vmware-desktop ~/license.lic
```

The first parameter is the name of the plugin, and the second parameter is the
path to the license file on disk. Please be sure to replace `~/license.lic`
with the path where you temporarily saved the downloaded license file to disk.
After you have installed the plugin license, you may remove the temporary file.

To verify the license installation, run:

```shell
$ vagrant
```

If the license is not installed correctly, you will see an error message.

## Upgrading to v1.x

It is **extremely important** that the VMware plugin is upgraded to 1.0.0 or
above. This release resolved critical security vulnerabilities. To learn more,
please [read our release announcement](https://www.hashicorp.com/blog/introducing-the-vagrant-vmware-desktop-plugin).

After upgrading, please verify that the following paths are empty. The upgrade
process should remove these for you, but for security reasons it is important
to double check. If you're a new user or installing the VMware provider on a
new machine, you may skip this step. If you're a Windows user, you may skip this
step as well.

The path `~/.vagrant.d/gems/*/vagrant-vmware-{fusion,workstation}`
should no longer exist. The gem `vagrant-vmware-desktop` may exist since this
is the name of the new plugin. If the old directories exist, remove them. An
example for a Unix-like shell is shown below:

```shell
# Check if they exist and verify that they're the correct paths as shown below.
$ ls ~/.vagrant.d/gems/*/vagrant-vmware-{fusion,workstation}
...

# Remove them
$ rm -rf ~/.vagrant.d/gems/*/vagrant-vmware-{fusion,workstation}
```

## Updating the Vagrant VMware Desktop plugin

The Vagrant VMware Desktop plugin can be updated directly from Vagrant. Run the
following command to update Vagrant to the latest version of the Vagrant VMware
Desktop plugin:

```shell
$ vagrant plugin update vagrant-vmware-desktop
```

## Frequently Asked Questions

**Q: I purchased a Vagrant VMware plugin license, but I did not receive an email?**<br>
First, please check your JUNK or SPAM folders. Since the license comes from an
automated system, it might have been flagged as spam by your email provider. If
you do not see the email there, please [contact support](mailto:support@hashicorp.com?subject=License Not Received)
and include the original order number.

**Q: Do I need to keep the Vagrant VMware plugin license file on disk?**<br>
After you have installed the Vagrant VMware plugin license, it is safe to remove
your copy from disk. Vagrant copies the license into its structure for reference
on boot.

**Q: I lost my original email, where can I download my Vagrant VMware plugin license again?**<br>
Please [contact support](mailto:support@hashicorp.com?subject=Lost My License&body=Hello support! I seem to have misplaced my Vagrant VMware license. Could you please send it to me? Thanks!). **Note:**
please contact support using the email address with which you made the
original purchase. If you use an alternate email, you will be asked to verify
that you are the owner of the requested license.

**Q: I upgraded my VMware product and now my license is invalid?**<br>
The Vagrant VMware plugin licenses are valid for specific VMware product
versions at the time of purchase. When new versions of VMware products are
released, significant changes to the plugin code are often required to support
this new version. For this reason, you may need to upgrade your current license
to work with the new version of the VMware product. Customers can check their
license upgrade eligibility by visiting the [License Upgrade Center](https://license.hashicorp.com/upgrade/vmware)
and entering the email address with which they made the original purchase.

Your existing license will continue to work with all previous versions of the
VMware products. If you do not wish to update at this time, you can rollback
your VMware installation to an older version.

**Q: Why is the Vagrant VMware plugin not working with my trial version of VMware Fusion/Workstation?**<br>
The Vagrant VMware Fusion and Vagrant VMware Workstation plugins are not
compatible with trial versions of the VMware products. We apologize for the
inconvenience.

**Q: How do I upgrade my currently installed Vagrant VMware plugin?**<br>
You can update the Vagrant VMware plugin to the latest version by re-running the
install command:

```shell
$ vagrant plugin install vagrant-vmware-desktop
```

## Support
If you have any issues purchasing, installing, or using the Vagrant VMware
plugins, please [contact support](mailto:support@hashicorp.com). To
expedite the support process, please include the
[Vagrant debug output](/docs/other/debugging.html) as a Gist if
applicable. This will help us more quickly diagnose your issue.
