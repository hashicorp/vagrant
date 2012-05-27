---
layout: extending
title: Extending Vagrant - Configuration

current: Configuration
---
# Configuration

The plugin API allows you to define new configuration classes which
can be used in Vagrantfiles. An example would be a `config.my_plugin`
available in Vagrantfile.

## Defining a Configuration Class

New configuration options are defined using a simple Ruby class
which inherits from `Vagrant::Config::Base`. In fact, the `config.my_plugin`,
is just an instance of some class which defined itself as the
`my_plugin` configuration class. An example class is shown below:

{% highlight ruby %}
class MyConfig < Vagrant::Config::Base
  attr_accessor :name
  attr_accessor :location
end

Vagrant.config_keys.register(:my_plugin) { MyConfig }
{% endhighlight %}

Given the above, if it was loaded, it could be used like so:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.my_plugin.name = "foo"
  config.my_plugin.location = "bar"
end
{% endhighlight %}

As you can see, configuration classes are very basic Ruby classes.
But don't forget to **register** the configuration class!

## Validation

Vagrant provides a standardized method of validating input for your
configuration classes. It is recommended that you _do not_ validate
input anywhere except through the `validate` method, since this will
allow Vagrant to output the error messages in a standard, unified, way.
Instead of explaining, an example is easiest to understand, building
upon the configuration class built in the previous section:

{% highlight ruby %}
class MyConfig < Vagrant::Config::Base
  attr_accessor :name
  attr_accessor :location

  def validate(env, errors)
    errors.add("Name must be filled out.") if !name
    errors.add("Name must be at least 5 characters.") if name && name.length < 5
  end
end
{% endhighlight %}

Pretty weak validations, I admit! But its up to you to decide how
detailed to get. Vagrant will automatically run these validations
after all the configuration is loaded, and will display a nicely formatted
error in the case validation fails.

## Accessing Configuration in Your Plugin

Once you have your configuration setup, it can be accessed from either
the `global_config` accessor on a `Vagrant::Environment` object, or the
'config' accessor on a `Vagrant::VM` object, depending on where it is
needed. For example:

{% highlight ruby %}
env.global_config.my_config.name
env.global_config.my_config.location
{% endhighlight %}

## Understanding Vagrant Config Merging

When configuring itself, Vagrant loads multiple configuration files, executes
each in isolation, and merges the final results to form the resulting configuration
for the entire environment. Vagrant automatically merges configuration classes
based on instance variables. Here are the basic rules of `A` being merged with `B`:

* Any set instance variables on `B` override those of `A`.
* Any instance variables beginning with `__` (double-underscore) are ignored. This
  is how configuration classes can store internal state they don't want copied
  around.

9 out of 10 times this works just as you would expect and want. However, there
are certain cases where you may want to configure the merging process. To do this,
you may override the `merge` method, which takes a single argument that is the other
instance to merge into. This should return a _new_ instance with the configurations
merged. Please see the [VM configuration](https://github.com/mitchellh/vagrant/blob/master/lib/vagrant/config/vm.rb#L32)
for a good example of this.

Finally, it is very important to note that you **should never, ever, ever** set
defaults to instance variables in an `initialize` method of your class. This will
cause that value to always win in overriding previously set values, which is
almost always a bug. To provide defaults, create a custom getter for your instance
variable and return the default if the instance variable is not yet set.
