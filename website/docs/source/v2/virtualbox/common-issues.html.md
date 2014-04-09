---
page_title: "Common Issues - VirtualBox Provider"
sidebar_current: "virtualbox-issues"
---

# Common Issues

This page lists some common issues people run into with VirtualBox as well
as solutions for those issues.

## Hanging on Windows

If Vagrant commands are hanging on Windows because they're communicating
to VirtualBox, this may be caused by a permissions issue with VirtualBox.
This is easy to fix. Start VirtualBox as a normal user or as an
administrator will prevent you from using it in the opposite way. Please keep
in mind that when Vagrant interacts with VirtualBox, it will interact with
it with the same access level as the console running Vagrant.

To fix this issue, completely shut down all VirtualBox machines and GUIs.
Wait a few seconds. Then, launch VirtualBox only with the access level you
wish to use.
