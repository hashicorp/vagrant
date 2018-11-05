---
layout: "docs"
page_title: "Installing Vagrant"
sidebar_current: "installation"
description: |-
  Installing Vagrant is extremely easy. Head over to the Vagrant downloads page
  and get the appropriate installer or package for your platform. Install the
  package using standard procedures for your operating system.
---

# Installing Vagrant

Installing Vagrant is extremely easy. Head over to the
[Vagrant downloads page](/downloads.html) and get the appropriate installer or
package for your platform. Install the package using standard procedures for
your operating system.

The installer will automatically add `vagrant` to your system path
so that it is available in terminals. If it is not found, please try
logging out and logging back in to your system (this is particularly
necessary sometimes for Windows).

<div class="alert alert-warning" role="alert">
  <strong>Looking for the gem install?</strong> Vagrant 1.0.x had the option to
  be installed as a <a href="https://en.wikipedia.org/wiki/RubyGems">RubyGem</a>.
  This installation method is no longer supported. If you have an old version
  of Vagrant installed via Rubygems, please remove it prior to installing newer
  versions of Vagrant.
</div>

<div class="alert alert-warning" role="alert">
  <strong>Beware of system package managers!</strong> Some operating system
  distributions include a vagrant package in their upstream package repos.
  Please do not install Vagrant in this manner. Typically these packages are
  missing dependencies or include very outdated versions of Vagrant. If you
  install via your system's package manager, it is very likely that you will
  experience issues. Please use the official installers on the downloads page.
</div>

## Running Multiple Hypervisors

Sometimes, certain hypervisors do not allow you to bring up virtual machines
if more than one hypervisor is in use. If you are lucky, you might see the following
error message come up when trying to bring up a virtual machine with Vagrant and
VirtualBox:

    There was an error while executing `VBoxManage`, a CLI used by Vagrant for controlling VirtualBox. The command and stderr is shown below.

    Command: ["startvm", <ID of the VM>, "--type", "headless"]

    Stderr: VBoxManage: error: VT-x is being used by another hypervisor (VERR_VMX_IN_VMX_ROOT_MODE).
    VBoxManage: error: VirtualBox can't operate in VMX root mode. Please disable the KVM kernel extension, recompile your kernel and reboot
    (VERR_VMX_IN_VMX_ROOT_MODE)
    VBoxManage: error: Details: code NS_ERROR_FAILURE (0x80004005), component ConsoleWrap, interface IConsole

Other operating systems like Windows will blue screen if you attempt to bring up
a VirtualBox VM with Hyper-V enabled. Below are a couple of ways to ensure you
can use Vagrant and VirtualBox if another hypervisor is present.

### Linux, VirtualBox, and KVM

The above error message is because another hypervisor (like KVM) is in use.
We must blacklist these in order for VirtualBox to run correctly.

First find out the name of the hypervisor:

    $ lsmod | grep kvm
    kvm_intel             204800  6
    kvm                   593920  1 kvm_intel
    irqbypass              16384  1 kvm

The one we're interested in is `kvm_intel`. You might have another.

Blacklist the hypervisor (run the following as root):

    # echo 'blacklist kvm-intel' >> /etc/modprobe.d/blacklist.conf

Restart your machine and try running vagrant again.

### Windows, VirtualBox, and Hyper-V

If you wish to use VirtualBox on Windows, you must ensure that Hyper-V is not enabled
on Windows. You can turn off the feature by running this Powershell command:

```powershell
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
```

You can also disable it by going through the Windows system settings:

- Right click on the Windows button and select ‘Apps and Features’.
- Select Turn Windows Features on or off.
- Unselect Hyper-V and click OK.

You might have to reboot your machine for the changes to take effect. More information
about Hyper-V can be read [here](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v).
