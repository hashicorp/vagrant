---
page_title: "vagrant rdp - Command-Line Interface"
sidebar_current: "cli-rdp"
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
...
```

The above command on Windows will execute `mstsc.exe /span config.rdp`,
allowing your RDP to span multiple desktops.
