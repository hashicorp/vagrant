---
layout: documentation
title: Documentation - Troubleshooting Common Problems

current: Troubleshooting
---
# Troubleshooting

Fixes for some common problems are denoted on this page. If the suggestions on
this page don't work, try [using Vagrant's debug log](/docs/debugging.html) or
[asking for support](/docs/support.html).

## Mount error on v-root: /vagrant

When you start up your guest, you may get the following message unexpectedly:

```
[default] -- v-root: /vagrant
The following SSH command responded with a non-zero exit status.
Vagrant assumes that this means the command failed!

mount -t vboxsf -o uid=`id -u vagrant`,gid=`id -g vagrant` v-root /vagrant
```

This is usually a result of the guest's package manager upgrading the kernel
without rebuilding the VirtualBox Guest Additions. To double-check that this
is the issue, connect to the guest and issue the following command:

`lsmod | grep vboxsf`

If that command does not return any output, it means that the VirtualBox Guest
Additions are not loaded. If the VirtualBox Guest Additions were previously
installed on the machine, you will more than likely be able to rebuild them
for the new kernel through the `vboxadd` initscript, like so:

`/etc/init.d/vboxadd setup`

