---
page_title: "Basic Usage - Provisioning"
sidebar_current: "provisioning-basic"
---

# Basic Usage of Provisioners

While Vagrant offers multiple options for how you are able to provision
your machine, there is a standard usage pattern as well as some important
points common to all provisioners that are important to know.

## Configuration

First, every provisioner is configured within your [Vagrantfile](/v2/vagrantfile/index.html)
using the `config.vm.provision` method call. For example, the Vagrantfile
below enables shell provisioning:

```ruby
Vagrant.configure("2") do |config|
  # ... other configuration

  config.vm.provision "shell", inline: "echo hello"
end
```

Every provisioner has an identifier, such as `"shell", used as the first
parameter to the provisioning configuration. Following that is basic key/value
for configuring that specific provisioner. Instead of basic key/value, you
can also use a Ruby block for a syntax that is more like variable assignment.
The following is effectively the same as the prior example:

```ruby
Vagrant.configure("2") do |config|
  # ... other configuration

  config.vm.provision "shell" do |s|
    s.inline = "echo hello"
  end
end
```

The benefit of the block-based syntax is that with more than a couple options
it can greatly improve readability. Additionally, some provisioners, like
the Chef provisioner, have special methods that can be called within that
block to ease configuration that can't be done with the key/value approach.

## Multiple Provisioners

Multiple `config.vm.provision` methods can be used to define multiple
provisioners. These provisioners will be run in the order they're defined.
This is useful for a variety of reasons, but most commonly it is used so
that a shell script can bootstrap some of the system so that another provisioner
can take over later.

## Running Provisioners

Provisioners are run in three cases: `vagrant up`, `vagrant reload`, and
`vagrant provision`.

A `--no-provision` flag can be passed to `up` and `reload` if you don't
want to run provisioners. Likewise, you can pass `--provision` to force
provisioning.

The `--provision-with` flag can be used if you only want to run a
specific provisioner if you have multiple provisioners specified. For
example, if you have a shell and Puppet provisioner and only want to
run the shell one, you can do `vagrant provision --provision-with shell`.
