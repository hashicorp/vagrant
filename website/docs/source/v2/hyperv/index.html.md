---
page_title: "Hyper-V Provider"
sidebar_current: "hyperv"
---

# Hyper-V

Vagrant comes with support out of the box for [Hyper-V](http://en.wikipedia.org/wiki/Hyper-V),
a native hypervisor written by Microsoft. Hyper-V is available by default for
almost all Windows 8.1 installs.

The Hyper-V provider is compatible with Windows 8.1 only. Prior versions
of Hyper-V do not include the necessary APIs for Vagrant to work.

Hyper-V must be enabled prior to using the provider. Most Windows installations
will not have Hyper-V enabled by default. To enable Hyper-V, go to
"Programs and Features" and check the box next to "Hyper-V."

<div class="alert alert-block alert-warn">
<strong>Warning:</strong> Enabling Hyper-V will cause VirtualBox, VMware,
and any other virtualization technology to no longer work. See
<a href="http://www.hanselman.com/blog/SwitchEasilyBetweenVirtualBoxAndHyperVWithABCDEditBootEntryInWindows81.aspx">this blog post</a>
for an easy way to create a boot entry to boot Windows without Hyper-V
enabled, if there will be times you'll need other hypervisors.
</div>
