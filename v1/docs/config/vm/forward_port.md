---
layout: documentation
title: Documentation - Vagrantfile - config.vm.forward_port

current: Vagrantfile
---
# config.vm.forward_port

Configuration key: `config.vm.forward_port`

This configuration directive is used to tell Vagrant to setup
a forwarded port. Forwarded ports allow you to access ports within
the virtual machine. This directive can be used multiple times within
a Vagrantfile. The basic usage is:

{% highlight ruby %}
Vagrant::Config.run do |config|
  # ...
  config.vm.forward_port 80, 8080
end
{% endhighlight %}

This tells Vagrant to configure the VirtualBox networking such that
network traffic sent to port 8080 on the host machine will be delivered
to port 80 on the guest machine.

As an optional 3rd parameter, you may pass an options hash. Currently
accepted options are:

* `:adapter` - This is the adpater number that the forwarded port
  definition should be attached to. Forwarded ports can only be attached
  to NAT devices.
* `:auto` - If this is set to `true` then Vagrant will automatically
  try to change the host port if it finds it would collide with any
  other forwarded port. If this is `false` (default) then an error
  will be shown instead.
* `:protocol` - This allows specifying the protocol that the forwarded port
  will use. The default protocol, if none is specified, is `:tcp`.

