---
layout: "docs"
page_title: "Custom Configuration - Plugin Development"
sidebar_current: "plugins-configuration"
description: |-
  This page documents how to add new configuration options to Vagrant,
  settable with "config.YOURKEY" in Vagrantfiles. Prior to reading this,
  you should be familiar with the plugin development basics.
---

# Plugin Development: Configuration

This page documents how to add new configuration options to Vagrant,
settable with `config.YOURKEY` in Vagrantfiles. Prior to reading this,
you should be familiar with the
[plugin development basics](/docs/plugins/development-basics.html).

<div class="alert alert-warning">
  <strong>Warning: Advanced Topic!</strong> Developing plugins is an
  advanced topic that only experienced Vagrant users who are reasonably
  comfortable with Ruby should approach.
</div>

## Definition Component

Within the context of a plugin definition, new configuration keys can be defined
like so:

```ruby
config "foo" do
  require_relative "config"
  Config
end
```

Configuration keys are defined with the `config` method, which takes as an
argument the name of the configuration variable as the argument. This
means that the configuration object will be accessible via `config.foo`
in Vagrantfiles. Then, the block argument returns a class that implements
the `Vagrant.plugin(2, :config)` interface.

## Implementation

Implementations of configuration keys should subclass `Vagrant.plugin(2, :config)`,
which is a Vagrant method that will return the proper subclass for a version
2 configuration section. The implementation is very simple, and acts mostly
as a plain Ruby object. Here is an example:

```ruby
class Config < Vagrant.plugin(2, :config)
  attr_accessor :widgets

  def initialize
    @widgets = UNSET_VALUE
  end

  def finalize!
    @widgets = 0 if @widgets == UNSET_VALUE
  end
end
```

When using this configuration class, it looks like the following:

```ruby
Vagrant.configure("2") do |config|
  # ...

  config.foo.widgets = 12
end
```

Easy. The only odd thing is the `UNSET_VALUE` bits above. This is actually
so that Vagrant can properly automatically merge multiple configurations.
Merging is covered in the next section, and `UNSET_VALUE` will be explained
there.

## Merging

Vagrant works by loading [multiple Vagrantfiles and merging them](/docs/vagrantfile/#load-order).
This merge logic is built-in to configuration classes. When merging two
configuration objects, we will call them "old" and "new", it'll by default
take all the instance variables defined on "new" that are not `UNSET_VALUE`
and set them onto the merged result.

The reason `UNSET_VALUE` is used instead of Ruby's `nil` is because
it is possible that you want the default to be some value, and the user
actually wants to set the value to `nil`, and it is impossible for Vagrant
to automatically determine whether the user set the instance variable, or
if it was defaulted as nil.

This merge logic is what you want almost every time. Hence, in the example
above, `@widgets` is set to `UNSET_VALUE`. If we had two Vagrant configuration
objects in the same file, then Vagrant would properly merge the follows.
The example below shows this:

```ruby
Vagrant.configure("2") do |config|
  config.widgets = 1
end

Vagrant.configure("2") do |config|
  # ... other stuff
end

Vagrant.configure("2") do |config|
  config.widgets = 2
end
```

If this were placed in a Vagrantfile, after merging, the value of widgets
would be "2".

The `finalize!` method is called only once ever on the final configuration
object in order to set defaults. If `finalize!` is called, that configuration
will never be merged again, it is final. This lets you detect any `UNSET_VALUE`
and set the proper default, as we do in the above example.

Of course, sometimes you want custom merge logic. Let us say we
wanted our widgets to be additive. We can override the `merge` method to
do this:

```ruby
class Config < Vagrant.config("2", :config)
  attr_accessor :widgets

  def initialize
    @widgets = 0
  end

  def merge(other)
    super.tap do |result|
      result.widgets = @widgets + other.widgets
    end
  end
end
```

In this case, we did not use `UNSET_VALUE` for widgets because we did not
need that behavior. We default to 0 and always merge by summing the
two widgets. Now, if we ran the example above that had the 3 configuration
blocks, the final value of widgets would be "3".

## Validation

Configuration classes are also responsible for validating their own
values. Vagrant will call the `validate` method to do this. An example
validation method is shown below:

```ruby
class Config < Vagrant.plugin("2", :config)
  # ...

  def validate(machine)
    errors = _detected_errors
    if @widgets <= 5
      errors << "widgets must be greater than 5"
    end

    { "foo" => errors }
  end
end
```

The validation method is given a `machine` object, since validation is
done for each machine that Vagrant is managing. This allows you to
conditionally validate some keys based on the state of the machine and so on.

The `_detected_errors` method returns any errors already detected by Vagrant,
such as unknown configuration keys. This returns an array of error messages,
so be sure to turn it into the proper Hash object to return later.

The return value is a Ruby Hash object, where the key is a section name,
and the value is a list of error messages. These will be displayed by
Vagrant. The hash must not contain any values if there are no errors.

## Accessing

After all the configuration options are merged and finalized, you will likely
want to access the finalized value in your plugin. The initializer function
varies with each type of plugin, but *most* plugins expose an initializer like
this:

```ruby
def initialize(machine, config)
  @machine = machine
  @config  = config
end
```

When authoring a plugin, simply call `super` in your initialize function to
setup these instance variables:

```ruby
def initialize(*)
  super

  @config.is_now_available
  # ...existing code
end

def my_helper
  @config.is_here_too
end
```

For examples, take a look at Vagrant's own internal plugins in the `plugins`
folder in Vagrant's source on GitHub.
