---
layout: "docs"
page_title: "Basic Usage - Provisioning"
sidebar_current: "provisioning-basic"
description: |-
  While Vagrant offers multiple options for how you are able to provision
  your machine, there is a standard usage pattern as well as some important
  points common to all provisioners that are important to know.
---

# Basic Usage of Provisioners

While Vagrant offers multiple options for how you are able to provision
your machine, there is a standard usage pattern as well as some important
points common to all provisioners that are important to know.

## Configuration

First, every provisioner is configured within your
[Vagrantfile](/docs/vagrantfile/)
using the `config.vm.provision` method call. For example, the Vagrantfile
below enables shell provisioning:

```ruby
Vagrant.configure("2") do |config|
  # ... other configuration

  config.vm.provision "shell", inline: "echo hello"
end
```

Every provisioner has a type, such as `"shell"`, used as the first
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
block to ease configuration that cannot be done with the key/value approach,
or you can use this syntax to pass arguments to a shell script.

The attributes that can be set in a single-line are the attributes that
are set with the `=` style, such as `inline = "echo hello"` above. If the
style is instead more of a function call, such as `add_recipe "foo"`, then
this cannot be specified in a single line.

Provisioners can also be named (since 1.7.0). These names are used cosmetically for output
as well as overriding provisioner settings (covered further below). An example
of naming provisioners is shown below:

```ruby
Vagrant.configure("2") do |config|
  # ... other configuration

  config.vm.provision "bootstrap", type: "shell" do |s|
    s.inline = "echo hello"
  end
end
```

Naming provisioners is simple. The first argument to `config.vm.provision`
becomes the name, and then a `type` option is used to specify the provisioner
type, such as `type: "shell"` above.

## Running Provisioners

Provisioners are run in three cases: the initial `vagrant up`, `vagrant
provision`, and `vagrant reload --provision`.

A `--no-provision` flag can be passed to `up` and `reload` if you do not
want to run provisioners. Likewise, you can pass `--provision` to force
provisioning.

The `--provision-with` flag can be used if you only want to run a
specific provisioner if you have multiple provisioners specified. For
example, if you have a shell and Puppet provisioner and only want to
run the shell one, you can do `vagrant provision --provision-with shell`.
The arguments to `--provision-with` can be the provisioner type (such as
"shell") or the provisioner name (such as "bootstrap" from above).

## Run Once or Always

By default, provisioners are only run once, during the first `vagrant up`
since the last `vagrant destroy`, unless the `--provision` flag is set,
as noted above.

Optionally, you can configure provisioners to run on every `up` or
`reload`. They will only be not run if the `--no-provision` flag is
explicitly specified. To do this set the `run` option to "always",
as shown below:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "shell", inline: "echo hello",
    run: "always"
end
```

You can also set `run:` to `"never"` if you have an optional provisioner
that you want to mention to the user in a "post up message" or that
requires some other configuration before it is possible, then call this
with `vagrant provision --provision-with bootstrap`.

If you are using the block format, you must specify it outside
of the block, as shown below:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "shell", run: "always" do |s|
    s.inline = "echo hello"
  end
end
```

## Multiple Provisioners

Multiple `config.vm.provision` methods can be used to define multiple
provisioners. These provisioners will be run in the order they're defined.
This is useful for a variety of reasons, but most commonly it is used so
that a shell script can bootstrap some of the system so that another provisioner
can take over later.

If you define provisioners at multiple "scope" levels (such as globally
in the configuration block, then in a
[multi-machine](/docs/multi-machine/) definition, then maybe
in a [provider-specific override](/docs/providers/configuration.html)),
then the outer scopes will always run _before_ any inner scopes. For
example, in the Vagrantfile below:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "shell", inline: "echo foo"

  config.vm.define "web" do |web|
    web.vm.provision "shell", inline: "echo bar"
  end

  config.vm.provision "shell", inline: "echo baz"
end
```

The ordering of the provisioners will be to echo "foo", "baz", then
"bar" (note the second one might not be what you expect!). Remember:
ordering is _outside in_.

With multiple provisioners, use the `--provision-with` setting along
with names to get more fine grained control over what is run and when.

## Overriding Provisioner Settings

<div class="alert alert-warning">
  <strong>Warning: Advanced Topic!</strong> Provisioner overriding is
  an advanced topic that really only becomes useful if you are already
  using multi-machine and/or provider overrides. If you are just getting
  started with Vagrant, you can safely skip this.
</div>

When using features such as [multi-machine](/docs/multi-machine/)
or [provider-specific overrides](/docs/providers/configuration.html),
you may want to define common provisioners in the global configuration
scope of a Vagrantfile, but override certain aspects of them internally.
Vagrant allows you to do this, but has some details to consider.

To override settings, you must assign a name to your provisioner.

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "foo", type: "shell",
    inline: "echo foo"

  config.vm.define "web" do |web|
    web.vm.provision "foo", type: "shell",
      inline: "echo bar"
  end
end
```

In the above, only "bar" will be echoed, because the inline setting
overloaded the outer provisioner. This overload is only effective
within that scope: the "web" VM. If there were another VM defined,
it would still echo "foo" unless it itself also overloaded the
provisioner.

**Be careful with ordering.** When overriding a provisioner in
a sub-scope, the provisioner will run at _that point_. In the example
below, the output would be "foo" then "bar":

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "foo", type: "shell",
    inline: "echo ORIGINAL!"

  config.vm.define "web" do |web|
    web.vm.provision "shell",
      inline: "echo foo"
    web.vm.provision "foo", type: "shell",
      inline: "echo bar"
  end
end
```

If you want to preserve the original ordering, you can specify
the `preserve_order: true` flag:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "do-this",
    type: "shell",
    preserve_order: true,
    inline: "echo FIRST!"
  config.vm.provision "then-this",
    type: "shell",
    preserve_order: true,
    inline: "echo SECOND!"
end
```
