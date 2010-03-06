---
layout: getting_started
title: Getting Started - Port Forwarding
---
# Port Forwarding

So we now have this virtual environment running all these servers
and processes. Great! But what's the use if we can't access them from
our _outside_ of the virtual environment? Well, it turns out Vagrant has
a built-in feature to handle just that: port forwarding.

Port forwarding allows you to specify ports on the host machine to forward
to the guest machine. This allows you to access your web services using
your own browser on your machine while the server actually sits and runs
within a virtual machine.

## Creating a Forwarded Port

In our case, we just want to forward Apache. Port forwarding is specified
in the Vagrantfile, like so:

{% highlight ruby %}
Vagrant::Config.run do |config|
  # Forward guest port 80 to host port 4567 and name the mapping "web"
  config.vm.forward_port("web", 80, 4567)
end
{% endhighlight %}

`forward_port` is a method which takes three arguments:

* **name** - A name of the mapping. This name must be unique, otherwise
  if its repeated it will be overwritten. This name is only used internally.
* **guest port** - The port on the virtual machine
* **host port** - The port on your local machine you want forwarded

## Applying Forwarded Ports

Forwarded ports are applied during `vagrant up` like any other configuration.
But if you already have a running system, calling `vagrant reload` will
apply them without re-importing and re-building everything.

Note that forwarding ports requires a virtual machine restart since VirtualBox
won't pick up on the forwarded ports until it is completely restarted.

## Results!

At this point, after running `vagrant up`, you should be able to take your
regular old browser to `localhost:8080` and see the following page. Sure,
it's an error page, but it means that rails is running and everything is
working!

![Success!](/images/getting-started/success.jpg)