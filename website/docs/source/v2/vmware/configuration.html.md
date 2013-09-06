---
page_title: "Configuration- VMware Provider"
sidebar_current: "vmware-configuration"
---

# Configuration

While VMware providers are a drop-in replacement for VirtualBox, there are
some additional features that are exposed that allow you to more finely
configure VMware-specific aspects of your machines.

## "VMware Fusion.app" Location

The provider by default looks for VMware Fusion in "/Applications" and
"~/Applications." If you put your applications in some other place, you'll
have to manually tell Vagrant where VMware Fusion is.

This can be done with the `VAGRANT_VMWARE_FUSION_APP` environmental variable.

For example, if you put your applications in an "/Apps" directory, you
would configure Vagrant like this:

```
$ export VAGRANT_VMWARE_FUSION_APP="/Apps/VMware Fusion.app"
$ vagrant up --provider=vmware_fusion
```

## VM Clone Directory

By default, the VMware provider will clone the VMware VM in the box
to the ".vagrant" folder relative to the folder where the Vagrantfile is.
Usually, this is fine. For some people, for example those who use a
differential backup software such as Time Machine, this is very annoying
because you can't regularly ignore giant virtual machines as part of backups.

The directory where the provider clones the virtual machine can be
customized by setting the `VAGRANT_VMWARE_CLONE_DIRECTORY` environmental
variable. This doesn't need to be unique per project. Each project will
get a different sub-directory within this folder. Therefore, it is safe to
set this systemwide.

## Virtual Machine GUI

The VMware provider generally starts the virtual machines
in headless mode. If you'd like to see the UI because you're running
a desktop within the VM, or if you need to debug potential boot issues
with the VM, you can configure the VMware provider to boot with the
GUI:

```ruby
config.vm.provider "vmware_fusion" do |v|
  v.gui = true
end
```

Use "vmware_workstation" if you're using VMware workstation.

## VMX Customization

If you want to add or remove specific keys from the VMX file, you can do
that:

```ruby
config.vm.provider "vmware_fusion" do |v|
  v.vmx["custom-key"]  = "value"
  v.vmx["another-key"] = nil
end
```

Use "vmware_workstation" if you're using VMware workstation.

In the example above, the "custom-key" key will be set to "value" and the
"another-key" key will be removed from the VMX file.

VMX customization is done as the final step before the VMware machine is
booted, so you have the ability to possibly undo or misconfigure things
that Vagrant has set up itself.

VMX is an undocumented format and there is no official reference for
the available keys and values. This customization option is exposed for
people who have knowledge of exactly what they want.

The most common keys people look for are setting memory and CPUs.
The example below sets both:

```ruby
config.vm.provider "vmware_fusion" do |v|
  v.vmx["memsize"] = "1024"
  v.vmx["numvcpus"] = "2"
end
```
