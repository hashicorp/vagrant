---
layout: extending
title: Extending Vagrant - Configuration
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
  configures :my_config

  attr_accessor :name
  attr_accessor :location
end
{% endhighlight %}

Important notes:

* `configures` is the important call here, which registers the configuration
  class as `config.my_config` with Vagrant.
* The rest of the class is just a regular Ruby class. Nothing sneaky.

Given the above, if it was loaded, it could be used like so:

{% highlight ruby %}
Vagrant::Config.run do |config|
  config.my_config.name = "foo"
  config.my_config.location = "bar"
end
{% endhighlight %}

## Validation

Vagrant provides a standardized method of validating input for your
configuration classes. It is recommended that you _do not_ validate
input anywhere except through the `validate` method, since this will
allow Vagrant to output the error messages in a standard, unified, way.
Instead of explaining, an example is easiest to understand, building
upon the configuration class built in the previous section:

{% highlight ruby %}
class MyConfig < Vagrant::Config::Base
  configures :my_config

  attr_accessor :name
  attr_accessor :location

  def validate(errors)
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

Once you have your configuration setup, it can be accessed from the
`config` accessor on a `Vagrant::Environment` object. For example:

{% highlight ruby %}
env.config.my_config.name
env.config.my_config.location
{% endhighlight %}
