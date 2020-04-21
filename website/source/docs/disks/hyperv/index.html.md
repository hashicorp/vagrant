---
layout: "docs"
page_title: "Disks for Hyper-V Provider"
sidebar_current: "disks-providers-hyperv"
description: |-
  Vagrant comes with support out of the box for Hyper-V, a free,
  cross-platform consumer virtualization product.
---

# Hyper-V

<div class="alert alert-warning">
  <strong>Warning!</strong> This feature is experimental and may break or
  change in between releases. Use at your own risk. It currently is not officially
  supported or functional.

  This feature currently reqiures the experimental flag to be used. To explicitly enable this feature, you can set the experimental flag to:

  ```
  VAGRANT_EXPERIMENTAL="disks"
  ```

  Please note that `VAGRANT_EXPERIMENTAL` is an environment variable. For more
  information about this flag visit the [Experimental docs page](/docs/experimental/)
  for more info. Without this flag enabled, any disks defined will not be configured.
</div>

Because of how Hyper-V handles disk management, a Vagrant guest _must_ be powered
off for any changes to be applied to a guest. If you make a configuration change
with a guests disk, you will need to `vagrant reload` the guest for any changes
to be applied.

For more information on how to use VirtualBox to configure disks for a guest, refer
to the [general usage](/docs/disks/usage.html) and [configuration](/docs/disks/configuration.html)
guide for more information.
