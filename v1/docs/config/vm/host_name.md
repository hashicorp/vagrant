---
layout: documentation
title: Documentation - Vagrantfile - config.vm.host_name

current: Vagrantfile
---
# config.vm.host_name

Configuration key: `config.vm.host_name`

Default value: `nil`

This can be set to the host name you wish the guest machine to have.
Vagrant will automatically execute the configuration necessary to
make this happen. Example:

{% highlight ruby %}
Vagrant::Config.run do |config|
  # ...
  config.vm.host_name = "pablo"
end
{% endhighlight %}
