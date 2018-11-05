---
layout: "docs"
page_title: "vagrant upload - Command-Line Interface"
sidebar_current: "cli-upload"
description: |-
  The "vagrant upload" command is used to upload files from the host
  to a guest machine.
---

# Upload

**Command: `vagrant upload source [destination] [name|id]`**

This command uploads files and directories from the host to the guest
machine.

## Options

* `destination` - Path on the guest machine to upload file or directory.

* `source` - Path to file or diretory on host to upload to guest machine.

* `--compress` - Compress the file or directory before uploading to guest machine.

* `--compression-type type` - Type of compression to use when compressing
  file or directory for upload. Defaults to `zip` for Windows guests and
  `tgz` for non-Windows guests. Valid values: `tgz`, `zip`.

* `--temporary` - Create a temporary location on the guest machine and upload
  files to that location.
