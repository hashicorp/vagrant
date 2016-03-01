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

  * `vmname` (string) - Name of virtual mashine as shown in Hyper-V manager.
    Defaults is taken from box image XML.
  * `cpus` (integer) - Number of virtual CPU given to mashine.
    Defaults is taken from box image XML.
  * `memory` (integer) - Number of MegaBytes allocated to VM at startup.
    Defaults is taken from box image XML.
  * `maxmemory` (integer) - Number of MegaBytes maximal allowed to allocate for VM
    This parameter is switch on Dynamic Allocation of memory.
    Defaults is taken from box image XML.
  * `vlan_id` (integer) - Number of Vlan ID for your guest network interface
    Defaults is not defined, vlan configuration will be untouched if not set.
  * `mac` (string) - MAC address for your guest network interface
    Default is not defined, MAC address will be dynamically assigned by Hyper-V if not set.
  * `ip_address_timeout` (integer) - The time in seconds to wait for the
    virtual machine to report an IP address. This defaults to 120 seconds.
    This may have to be increased if your VM takes longer to boot.
  * `differencing_disk` (boolean) - Switch to use differencing disk intead of cloning whole VHD.
