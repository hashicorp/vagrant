---
page_title: "Installation - VMware Provider"
sidebar_current: "vmware-installation"
---

# Installation

The Vagrant VMware provider can be installed using the standard plugin
installation procedure. VMware Fusion users should run:

```text
$ vagrant plugin install vagrant-vmware-fusion
```

VMware Workstation users should run:

```text
$ vagrant plugin install vagrant-vmware-workstation
```

For more information on plugin installation, please see the
[Vagrant plugin usage documentation](/v2/plugins/usage.html).

The Vagrant VMware plugins are commercial products provided by
[HashiCorp](https://www.hashicorp.com) and **require the purchase of a license**
to operate. To purchase a license, please visit the
[Vagrant VMware provider](http://www.vagrantup.com/vmware#buy-now) page. Upon
purchasing a license, you will receive a license file in your inbox. Download
this file and save it to a temporary location on your computer.

<div class="alert alert-block alert-warn">
  <strong>Warning!</strong> You cannot use your VMware product license as a
  Vagrant VMware plugin license. They are separate commercial products, each
  requiring their own license.
</div>

After installing the correct Vagrant VMware product plugin for your system, you
will need to install the license. For VMware Fusion users:

```text
$ vagrant plugin license vagrant-vmware-fusion ~/license.lic
```

For VMware Workstation users:

```text
$ vagrant plugin license vagrant-vmware-workstation ~/license.lic
```

The first parameter is the name of the plugin, and the second parameter is the
path to the license file on disk. Please be sure to replace `~/license.lic`
with the path where you temporarily saved the downloaded license file to disk.
After you have installed the plugin license, you may remove the temporary file.

To verify the license installation, run:

```text
$ vagrant plugin list
```

If the license is not installed correctly, you will see an error message.


## Frequently Asked Questions

**Q: I purchased a Vagrant VMware plugin license, but I did not receive an email?**<br>
First, please check your JUNK or SPAM folders. Since the license comes from an
automated system, it might have been flagged as spam by your email provider. If
you do not see the email there, please [contact support](mailto:support@hashicorp.com?subject=License Not Received)
and include the original order number.

**Q: Do you offer trial periods for the Vagrant VMware plugins?**<br>
We do not offer a trial mechanism at this time, but we do offer a 30-day, no
questions asked, 100% money-back guarantee. If you are not satisfied with the
product, contact us within 30 days and you will receive a full refund.

**Q: Do you offer educational discounts on the Vagrant VMware plugins?**<br>
A select number of educational discounts are available for students, staff, and
faculty. Please [contact support](mailto:support@hashicorp.com?subject=Educational Discounts&body=Hello support! I would like to learn more about educational discounts on the Vagrant VMware plugins. Thanks!) for more
information. You will be asked to verify your status as an employee of active
student.

**Q: Do I need to keep the Vagrant VMware plugin license file on disk?**<br>
After you have installed the Vagrant VMware plugin license, it is safe to remove
your copy from disk. Vagrant copies the license into its structure for reference
on boot.

**Q: I lost my original email, where can I download my Vagrant VMware plugin license again?**<br>
Please [contact support](mailto:support@hashicorp.com?subject=Lost My License&body=Hello support! I seem to have misplaced my Vagrant VMware license. Could you please send it to me? Thanks!). **Note:**
please contact support using the email address with which you made the
original purchase. If you use an alternate email, you will be asked to verify
that you are the owner of the requested license.

**Q: Where can I find the EULA for the Vagrant VMware plugins?**<br>
The [EULA for the Vagrant VMware plugins](http://www.vagrantup.com/vmware/eula)
is available on the Vagrant website.

**Q: Do you offer bulk/volume discounts for the Vagrant VMware plugins?**<br>
We certainly do! [Email support](mailto:support@hashicorp.com?subject=Bulk Discounts)
with the number of licenses you need and we can give you bulk pricing
information. Please note that bulk pricing requires the purchase of at least 150
seats.

**Q: I upgraded my VMware product and now my license is invalid?**<br>
The Vagrant VMware plugin licenses are valid for specific VMware product
versions at the time of purchase. When new versions of VMware products are
released, significant changes to the plugin code are often required to support
this new version. For this reason, you may need to upgrade your current license
to work with the new version of the VMware product. Customers can check their
license upgrade eligibility by visiting the [License Upgrade Center](http://license.hashicorp.com/upgrade/vmware2014)
and entering the email address with which they made the original purchase.

Your existing license will continue to work with all previous versions of the
VMware products. If you do not wish to update at this time, you can rollback
your VMware installation to an older version.

**Q: Why is the Vagrant VMware plugin not working with my trial version of VMware Fusion/Workstation?**<br>
The Vagrant VMware Fusion and Vagrant VMware Workstation plugins are not
compatible with trial versions of the VMware products. We apologize for the
inconvenience.

**Q: I accidentally bought the wrong Vagrant VMware plugin, can I switch?**<br>
Sure! Even though the Vagrant VMware Fusion plugin and the Vagrant VMware
Workstation plugin are different products, they are the same price and fall
under the same EULA. As such, we can transfer the license for you. Please
[contact support](mailto:support@hashicorp.com?subject=Transfer License).

**Q: Since each license comes with two "seats", can I use one seat for the Vagrant VMware Fusion plugin and one seat for the Vagrant VMware Workstation plugin?**<br>
Unfortunately this is not permitted. The Vagrant VMware Fusion plugin and the
Vagrant VMware Workstation plugin are separate products and cannot be shared in
this manner. We apologize for the inconvenience.

**Q: How do I upgrade my currently installed Vagrant VMware plugin?**<br>
You can update the Vagrant VMware plugin to the latest version by re-running the
install command. For VMware Fusion:

```text
$ vagrant plugin install vagrant-vmware-fusion
```

For VMWare Workstation:

```text
$ vagrant plugin install vagrant-vmware-workstation
```


## Support
If you have any issues purchasing, installing, or using the Vagrant VMware
plugins, please [contact support](http://www.vagrantup.com/support.html). To
expedite the support process, please include the
[Vagrant debug output](/v2/other/debugging.html) as a Gist or pastebin if
applicable. This will help us more quickly diagnose your issue.
