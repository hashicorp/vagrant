---
layout: "docs"
page_title: "Kernel Upgrade - VMware Provider"
sidebar_current: "providers-vmware-kernel-upgrade"
description: |-
  If as part of running your Vagrant environment with VMware, you perform
  a kernel upgrade, it is likely that the VMware guest tools will stop working.
  This breaks features of Vagrant such as synced folders and sometimes
  networking as well.
---

# Kernel Upgrade

If as part of running your Vagrant environment with VMware, you perform
a kernel upgrade, it is likely that the VMware guest tools will stop working.
This breaks features of Vagrant such as synced folders and sometimes
networking as well.

This page documents how to upgrade your kernel and keep your guest tools
functioning. If you are not planning to upgrade your kernel, then you can safely
skip this page.

## Enable Auto-Upgrade of VMware Tools

If you are running a common OS, VMware tools can often auto-upgrade themselves.
This setting is disabled by default. The Vagrantfile settings below will
enable auto-upgrading:

```ruby
# Ensure that VMWare Tools recompiles kernel modules
# when we update the linux images
$fix_vmware_tools_script = <<SCRIPT
sed -i.bak 's/answer AUTO_KMODS_ENABLED_ANSWER no/answer AUTO_KMODS_ENABLED_ANSWER yes/g' /etc/vmware-tools/locations
sed -i 's/answer AUTO_KMODS_ENABLED no/answer AUTO_KMODS_ENABLED yes/g' /etc/vmware-tools/locations
SCRIPT

Vagrant.configure("2") do |config|
  # ...

  config.vm.provision "shell", inline: $fix_vmware_tools_script
end
```

Note that this does not work for every OS, so `vagrant up` with the above
settings, do a kernel upgrade, and do a `vagrant reload`. If HGFS (synced
folders) and everything appears to be working, great! If not, then read on...

## Manually Reinstalling VMware Tools

At this point, you will have to manually reinstall VMware tools. The best
source of information for how to do this is the
[VMware documentation](https://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=1018414).

There are some gotchas:

  * Make sure you have the kernel headers properly installed. This varies
    by distro but is generally a package available via the package manager.

  * Watch the installation output carefully. Even if HGFS (synced folders)
    support failed to build, the installer will output that installing VMware
    tools was successful. Read the output to find any error messages.
