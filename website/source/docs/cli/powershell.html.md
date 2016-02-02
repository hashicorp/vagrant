---
layout: "docs"
page_title: "vagrant powershell - Command-Line Interface"
sidebar_current: "cli-powershell"
description: |-
  The "vagrant powershell" command is used to open a powershell prompt running
  inside the guest machine.
---

# PowerShell

**Command: `vagrant powershell`**

This will open a PowerShell prompt into a running Vagrant machine.

This command will only work if the machine supports PowerShell. Not every
environment will support PowerShell.

## Options

* `-c COMMAND` or `--command COMMAND` - This executes a single PowerShell command,
  prints out the stdout and stderr, and exits.
