---
page_title: "Multi-Machine"
sidebar_current: "multimachine"
---

# Multi-Machine

Vagrant is able to define and control multiple guest machines per
Vagrantfile. This is known as a "multi-machine" environment.

These machines are generally able to work together or are somehow associated
with each other. Here are some use-cases people are using multi-machine
environments for today:

* Accurately modeling a multi-server production topology, such as separating
  a web and database server.
* Modeling a distributed system and how they interact with each other.
* Testing an interface, such as an API to a service component.
* Disaster-case testing: machines dying, network partitions, slow networks,
  inconsistent world views, etc.

Historically, running complex environments such as these was done by
flattening them onto a single machine. The problem with that is that it is
an inaccurate model of the production setup, which can behave far differently.

Using the multi-machine feature of Vagrant, these environments can be modeled
in the context of a single Vagrant environment without losing any of the
benefits of Vagrant.

## Defining Multiple Machines

Multiple machines are defined within the same project [Vagrantfile](/v2/vagrantfile/index.html)
using the `config.vm.define` method call. This configuration directive
is a little funny, because it creates a Vagrant configuration within a
configuration. An example shows this best:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "shell", inline: "echo Hello"

  config.vm.define "web" do |web|
    web.vm.box = "apache"
  end

  config.vm.define "db" do |db|
    db.vm.box = "mysql"
  end
end
```

As you can see, `config.vm.define` takes a block with another variable. This
variable, such as `web` above, is the _exact_ same as the `config` variable,
except any configuration of the inner variable applies only to the machine
being defined. Therefore, any configuration on `web` will only affect the
`web` machine.

And importantly, you can continue to use the `config` object as well. The
configuration object is loaded and merged before the machine-specific configuration,
just like other Vagrantfiles within the
[Vagrantfile load order](/v2/vagrantfile/index.html#load-order).

If you're familiar with programming, this is similar to how languages have
different variable scopes.

## Controlling Multiple Machines

The moment more than one machine is defined within a Vagrantfile, the
usage of the various `vagrant` commands changes slightly. The change should
be mostly intuitive.

Most commands, such as `vagrant up`, begin requiring the name of the machine
to control. Using the example above, you could say `vagrant up web`, or
`vagrant up db`. If no name is specified, it is assumed you mean to perform
that operation on every machine. Therefore, `vagrant up` alone will bring
up both the web and DB machine.

Additionally, you can specify a regular expression for matching only
certain machines. This is useful in some cases where you specify many similar
machines, for example if you're testing a distributed service you may have
a `master` machine as well as a `slave0`, `slave1`, `slave2`, etc. If you
want to bring up all the slaves but not the master, you can just do
`vagrant up /slave[0-9]/`. If Vagrant sees a machine name within forward
slashes, it assumes you're using a regular expression.

## Communication Between Machines

In order to faciliate communication within machines in a multi-machine setup,
the various [networking](/v2/networking/index.html) options should be used.
In particular, the [private network](/v2/networking/private_network.html) can
be used to make a private network between multiple machines and the host.

## Specifying a Primary Machine

You can also specify a _primary machine_. The primary machine will be the
default machine used when a specific machine in a multi-machine environment
is not specified.

To specify a default, machine, just mark it primary when defining it. Only
one primary machine may be specified.

```ruby
config.vm.define "web", primary: true do |web|
  # ...
end
```
