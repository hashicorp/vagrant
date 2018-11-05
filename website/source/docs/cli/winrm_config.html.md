---
layout: "docs"
page_title: "vagrant winrm-config - Command-Line Interface"
sidebar_current: "cli-winrm_config"
description: |-
  The "vagrant winrm-config" command is used to output the WinRM configuration
  used to connect to the guest machine.
---

# WinRM Config

**Command: `vagrant winrm-config [name|id]`**

This will output the WinRM configuration used for connecting to
the guest machine. It requires that the WinRM communicator is in
use for the guest machine.

## Options

* `--host NAME` - Name of the host for the outputted configuration.
