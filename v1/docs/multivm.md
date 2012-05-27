---
layout: documentation
title: Documentation - Multi-VM Environments

current: Multi-VM
---
# Multi-VM Environments

Vagrant supports what are known as "Multi-VM Environments." These are Vagrant
environments which contain multiple virtual machines which typically work
together or are somehow associated with each other. An example of some uses of
Multi-VM environments:

* Accurately modeling a separate _web_ and _database_ server within the
  same development environment.
* Modeling a cluster of machines, and how they behave together.
* Testing an interface, such as API calls or a chat interface.
* Testing a load balancer configuration, or the effects of "unplugging"
  a machine.

Historically, running complex environments such as these was done by flattening
them onto a developer's machine. For example, in the case where there may typically
be a separate worker server which may process images, the web, queue, and workers
would all run side by side on the same development machine.

The problem with this is that it is an inaccurate model of the production setup.
Vagrant and Multi-VM environments allow developers to model complex multi-server
setups on a single development machine without getting in the way of the
development process (continue to use the same editors, tools, etc.).

## Defining Multiple VMs

The multiple VMs are all defined within the same single Vagrantfile which you're
probably already used to. A small example is shown below:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.define :web do |web_config|
    web_config.vm.box = "web"
    web_config.vm.forward_port 80, 8080
  end

  config.vm.define :db do |db_config|
    db_config.vm.box = "db"
    db_config.vm.forward_port 3306, 3306
  end
end
{% endhighlight %}

Using `config.vm.define`, you can create multiple VMs (as many as you'd like) within
a single Vagrantfile. The `web_config` or `db_config` variables used within the
definitions are the exact same, functionally, as a Vagrantfile's typical `config`.
This allows the VMs to have their own custom configuration on any configurable
value.

In the case above, we're defining two VMs: "web" and "db." These two VMs are based
on two different boxes. The web VM forwards port 80 while the database VM forwards
port 3306.

## Controlling Multiple VMs

The moment that multiple VMs are introduced in a Vagrantfile, the usage of
the various `vagrant` command line commands change slightly. This change is hopefully
mostly intuitive, and will be shown using a very simple example based on `vagrant up`.

In a single VM environment, `vagrant up` starts that VM. In a multi-VM environment
`vagrant up` starts _every_ VM. If a name is specified to the command such as
`vagrant up web` then it will start only that specific VM.

This pattern follows for every other command as well, although some don't implement
the "every VM" functionality when it doesn't make sense, such as `vagrant ssh`, which
requires that a VM name be specified if its in a multi-VM environment.

## Communication Between VMs

With multiple VMs up and running, the next step is to support inter-VM
communication so that, say, a web server can talk to its associated database
server.

This communication is typically done through [host-only networking](/docs/host_only_networking.html). There is an entire page dedicated to the topic, but a relatively simple
example is given below, based on the example given earlier:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.vm.define :web do |web_config|
    # ...
    web_config.vm.network :hostonly, "192.168.1.10"
  end

  config.vm.define :db do |db_config|
    # ...
    db_config.vm.network :hostonly, "192.168.1.11"
  end
end
{% endhighlight ruby %}

The above assigns a static IP to both the web and database VMs. This
static IP can then be used to communicate directly to the other VMs.
For more details on how to do things such as creating separate networks,
joining the same network from separate Vagrantfiles, etc. please read
the [host-only networking](/docs/host_only_networking.html) page.

<div class="alert alert-block alert-notice">
  <h3>All ports are open!</h3>
  <p>
    When assigning a static IP like the above, VirtualBox makes no attempt
    to block any access to any port. Therefore, it is up to you to make sure
    that the iptables or firewall are properly setup on each VM. This issue
    does not pose a security threat, since the network is private to your machine,
    but it is important to note for modeling production as accurately as possible.
  </p>
</div>

