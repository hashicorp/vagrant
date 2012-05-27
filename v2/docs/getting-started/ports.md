---
layout: getting_started
title: Getting Started - Port Forwarding

current: Port Forwarding
previous: Provisioning
previous_url: /docs/getting-started/provisioning.html
next: Packaging
next_url: /docs/getting-started/packaging.html
---
# Port Forwarding

At this point we have a virtual environment running with Apache serving
the basic web project. But so far we can only access it from within the
VM, using the command line. Vagrant's goal is to provide the benefit of
a virtualized environment without getting in your way. In order to access
your project, Vagrant has a feature known as port forwarding.

Port forwarding allows you to specify ports on the guest machine to forward
to the host machine. This enables you to access your web services using
your own browser on your machine while the server actually sits and runs
within a virtual machine.

## Specifying a Forwarded Port

In our case, we just want to forward Apache. Port forwarding is specified
in the Vagrantfile, like so:

{% highlight ruby %}
Vagrant::Config.run do |config|
  # Forward guest port 80 to host port 4567
  config.vm.forward_port 80, 4567
end
{% endhighlight %}

`forward_port` is a method which takes two arguments:

* **guest port** - The port on the virtual machine.
* **host port** - The port on your local machine you want to use to access
  the guest port.

## Applying Forwarded Ports

Forwarded ports are applied during `vagrant up` like any other configuration.
But if you already have a running system, calling `vagrant reload` will
apply them without re-importing and re-building everything.

Note that forwarding ports requires a virtual machine restart since VirtualBox
won't pick up on the forwarded ports until it is completely restarted.

## Results!

After running `vagrant up`, you should be able to take your
regular old browser to `localhost:4567` and see the index page we created
earlier. At this point, we have a fully functional VM ready for development for
a basic HTML website. It should be clear to see that if PHP, Rails, etc.
were setup, you could be developing those technologies as well.

For fun, you can also edit the `index.html` file, save it, refresh your
browser, and immediately see your changes served directly from your VM.
