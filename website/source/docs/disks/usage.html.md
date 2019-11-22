---
layout: "docs"
page_title: "Vagrant Disk Usage"
sidebar_current: "disks-usage"
description: |-
  Various Vagrant Disk examples
---

# Basic Usage

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
</div>

Below are some very simple examples of how to use Vagrant Disks.

## Examples

- Resizing a disk (primary)
- Attaching a new disk
- Using provider specific options
