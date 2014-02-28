---
page_title: "Configuration- Hyper-V Provider"
sidebar_current: "hyperv-configuration"
---

# Configuration

The Hyper-V provider has some provider-specific configuration options
you may set. A complete reference is shown below:

  * `ip_address_timeout` (integer) - The time in seconds to wait for the
    virtual machine to report an IP address. This defaults to 120 seconds.
    This may have to be increased if your VM takes longer to boot.
