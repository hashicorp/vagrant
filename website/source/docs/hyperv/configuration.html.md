---
layout: "docs"
page_title: "Configuration- Hyper-V Provider"
sidebar_current: "providers-hyperv-configuration"
description: |-
  The Vagrant Hyper-V provider has some provider-specific configuration options
  you may set.
---

# Configuration

The Vagrant Hyper-V provider has some provider-specific configuration options
you may set. A complete reference is shown below:

* `auto_start_action` (Nothing, StartIfRunning, Start) - Automatic start action for VM on host startup. Default: Nothing.
* `auto_stop_action` (ShutDown, TurnOff, Save) - Automatic stop action for VM on host shutdown. Default: ShutDown.
* `cpus` (integer) - Number of virtual CPUs allocated to VM at startup.
* `differencing_disk` (boolean) - **Deprecated** Use differencing disk instead of cloning entire VHD (use `linked_clone` instead) Default: false.
* `enable_virtualization_extensions` (boolean) - Enable virtualization extensions for the virtual CPUs. Default: false
* `enable_checkpoints` (boolean) Enable checkpoints of the VM. Default: true
* `enable_automatic_checkpoints` (boolean) Enable automatic checkpoints of the VM. Default: false
* `ip_address_timeout` (integer) - Number of seconds to wait for the VM to report an IP address. Default: 120.
* `linked_clone` (boolean) - Use differencing disk instead of cloning entire VHD. Default: false
* `mac` (string) - MAC address for the guest network interface
* `maxmemory` (integer) - Maximum number of megabytes allowed to be allocated for the VM. When set Dynamic Memory Allocation will be enabled.
* `memory` (integer) - Number of megabytes allocated to VM at startup. If `maxmemory` is set, this will be amount of memory allocated at startup.
* `vlan_id` (integer) - VLAN ID for the guest network interface.
* `vmname` (string) - Name of virtual machine as shown in Hyper-V manager. Default: Generated name.
* `vm_integration_services` (Hash) - Hash to set the state of integration services. (Note: Unknown key values will be passed directly.)
  * `guest_service_interface` (boolean)
  * `heartbeat` (boolean)
  * `key_value_pair_exchange` (boolean)
  * `shutdown` (boolean)
  * `time_synchronization` (boolean)
  * `vss` (boolean)

## VM Integration Services

The `vm_integration_services` configuration option consists of a simple Hash. The key values are the
names of VM integration services to enable or disable for the VM. Vagrant includes an internal
mapping of known services which allows them to be provided in a "snake case" format. When a provided
key is unknown, the key value is used "as-is" without any modifications.

For example, if a new `CustomVMSRV` VM integration service was added and Vagrant is not aware of this
new service name, it can be provided as the key value explicitly:

```ruby
config.vm.provider "hyperv" do |h|
  h.vm_integration_services = {
    guest_service_interface: true,
    CustomVMSRV: true
  }
end
```

This example would enable the `GuestServiceInterface` (which Vagrant is aware) and `CustomVMSRV` (which
Vagrant is _not_ aware) VM integration services.
