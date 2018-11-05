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

This will open a PowerShell prompt on the host into a running Vagrant guest machine.

This command will only work if the machines supports PowerShell. Not every
environment will support PowerShell. At the moment, only Windows is supported
with this command.

## Options

* `-c COMMAND` or `--command COMMAND` - This executes a single PowerShell command,
  prints out the stdout and stderr, and exits.
