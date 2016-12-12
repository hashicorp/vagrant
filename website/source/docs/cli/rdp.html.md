---
layout: "docs"
page_title: "vagrant rdp - Command-Line Interface"
sidebar_current: "cli-rdp"
description: |-
  The "vagrant rdp" command is used to start an RDP client for a remote desktop
  session with the guest machine.
---

# RDP

**Command: `vagrant rdp`**

This will start an RDP client for a remote desktop session with the
guest. This only works for Vagrant environments that support remote
desktop, which is typically only Windows.

## Raw Arguments

You can pass raw arguments through to your RDP client on the
command-line by appending it after a `--`. Vagrant just passes
these through. For example:

```
$ vagrant rdp -- /span
```

The above command on Windows will execute `mstsc.exe /span config.rdp`,
allowing your RDP to span multiple desktops.


On Darwin hosts, such as Mac OS X, the additional arguments are added to the
generated RDP configuration file. Since these files can contain multiple options
with different spacing, you _must_ quote multiple arguments. For example:

```
$ vagrant rdp -- "screen mode id:i:0" "other config:s:value"
```

Note that as of the publishing of this guide, the Microsoft RDP Client for Mac
does _not_ perform validation on the configuration file. This means if you
specify an invalid configuration option or make a typographical error, the
client will silently ignore the error and continue!
