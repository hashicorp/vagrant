---
layout: documentation
title: Documentation - Vagrantfile - config.vm.customize

current: Vagrantfile
---
# config.vm.customize

Configuration key: `config.vm.customize`

This configuration directive may be used multiple times in a Vagrantfile.
This is a function, rather than a settable attribute, and the only argument
is an array of commands to send to `VBoxManage` just prior to the VM being
booted. This can be used to customize any aspect of the VirtualBox virtual
machine that Vagrant doesn't expose configuration options for. For example,
if you want to increase the memory available on a VM:

{% highlight ruby %}
Vagrant::Config.run do |config|
  # ..
  config.vm.customize ["modifyvm", :id, "--memory", 1024]
end
{% endhighlight %}

The special value `:id`, when found in the array, is replaced with the
actual UUID of the virtual machine that Vagrant is creating.
