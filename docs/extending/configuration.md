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

## Accessing Configuration in Your Plugin

TODO
