---
layout: extending
title: Extending Vagrant - Testing
---
# Testing

Ruby is a very test-driven community. As such, simply providing a plugin
API wouldn't satisfy anyone, so Vagrant also provides test helpers to
make automated testing much easier. These helpers are provided in the
module `Vagrant::TestHelpers` and are test-framework agnostic, meaning
they'll work with `Test::Unit`, `RSpec`, `Shoulda`, etc.

The test helpers provide a way to do the following:

* Create custom Vagrantfile contents
* Create a `Vagrant::Environment` based on the custom Vagrantfiles
* Create Vagrant boxes
* Create action environments to test middlewares

Some more test helpers are planned, but these helpers come a long way
in making testing a breeze.

Below are a few examples of how to use these helpers to test different
parts of a plugin. All the examples below are using bare `test/unit`
to show how to test. It should be clear how to extend this to other
test frameworks.

## Example: Testing Configuration

Assuming we have the following configuration class:

{% highlight ruby %}
class MyConfig < Vagrant::Config::Base
  configures :my_config
  attr_accessor :name

  def validate(errors)
    errors.add("You need a name.") if !name
  end
end

We can test it with the following:

{% highlight ruby %}
class MyConfigTest < Test::Unit::TestCase
  def setup do
    @config = MyConfig.new
    @errors = Vagrant::Config::ErrorRecorder.new
  end

  def test_my_config_invalid_with_no_name
    @config.validate(@errors)

    # Verify there was a problem
    assert !@errors.errors.empty?
  end

  def test_my_config_valid_with_name
    @config.name = "Mitchell"
    @config.validate(@errors)

    # Verify there is no problem
    assert @errors.errors.empty?
  end
end
{% endhighlight %}

The above tests that:

* The configuration class is invalid with no name set
* The configuration class is valid with a name set

## Example: Testing a Middleware

TODO

## Example: Testing a Command

TODO
