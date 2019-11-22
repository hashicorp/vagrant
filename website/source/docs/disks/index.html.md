---
layout: "docs"
page_title: "Vagrant Disks"
sidebar_current: "disks"
description: |-
  Introduction to Vagrant Disks
---

# Vagrant Disks

<div class="alert alert-warning">
  <strong>Warning!</strong> This feature is experimental and may break or
  change in between releases. Use at your own risk. It currently is not officially
  supported or functional.

  This feature currently reqiures the experimental flag to be used. To explicitly enable this feature, you can set the experimental flag to:

  ```
  VAGRANT_EXPERIMENTAL="disk_base_config"
  ```

  Please note that `VAGRANT_EXPERIMENTAL` is an environment variable. For more
  information about this flag visit the [Experimental docs page](/docs/experimental/)
  for more info. Without this flag enabled, triggers with the `:type` option
  will be ignored.

  <strong>NOTE:</strong> Vagrant disks is currently a future feature for Vagrant that is not yet supported.
  Some documentation exists here for future reference, however the Disk feature is
  not yet functional. Please be patient for us to develop this new feature, and stay
  tuned for a future release of Vagrant with this new functionality!
</div>

For more information about what options are available for configuring disks, see the
[configuration section](/docs/disks/configuration.html).
