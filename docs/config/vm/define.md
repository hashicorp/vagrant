---
layout: documentation
title: Documentation - Vagrantfile - config.vm.define

current: Vagrantfile
---
# config.vm.define

Configuration key: `config.vm.define`

This is used to define a VM in a [multi-VM environment](/docs/multivm.html).
Please see the [multi-VM documentation](/docs/multivm.html) to learn more about
multi-VMs. The rest of the documentation for this configuration directive will
assume basic knowledge of this feature.

VMs are defined as follows:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.define :foo do |foo_config|
    # ...
  end
end
{% endhighlight %}

Specifically, `config.vm.define` takes a single required parameter which is the
name of the virtual machine. This only has to be some value that can be converted
to a string. A block (callback in Ruby) must be given as well which is called
to configure that VM. The parameter to the block is the same as any normal
`config` object and will only apply to that VM. Additionally, the sub-VM
will inherit any of the values set on the global `config`.

This configuration directive also takes an optional second parameter which
is an options hash. Currently, the only recognized option is `:primary`. When
this is set to `true`, Vagrant considers that virtual machine the _primary_
virtual machine. When a command that typically requires a target VM such as
`vagrant up` is called, the primary VM will be used if no target is given.
