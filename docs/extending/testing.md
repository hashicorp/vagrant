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
{% endhighlight %}

We can test it with the following:

{% highlight ruby %}
class MyConfigTest < Test::Unit::TestCase
  def setup
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

Given that we have the following middleware class:

{% highlight ruby %}
class MyMiddleware
  def initialize(app, env)
    @app = app
  end

  def call(env)
    env["vm"].destroy
    @app.call(env)
  end
end
{% endhighlight %}

The following class tests this:

{% highlight ruby %}
class MyMiddlewareTest < Test::Unit::TestCase
  include Vagrant::TestHelpers

  def setup
    @app, @env = action_env
    @middleware = MyMiddleware.new(@app, @env)

    # Stub this so it doesn't actually do anything
    @env["vm"].stubs(:destroy)
  end

  def test_destroys_vm
    @env["vm"].expects(:destroy).once
    @middleware.call(@env)
  end

  def test_calls_the_next_app
    @app.expects(:call).once
    @middleware.call(@env)
  end
end
{% endhighlight %}

The above tests that:

* The middleware properly destroys the VM
* The middleware properly calls the next application.

Middleware tests often use mocks/stubs like the above to test the interaction
with the actual VM objects.

## Example: Testing a Command

Given the following command which runs the registered action `:foo` on every
VM:

{% highlight ruby %}
class MyCommand < Vagrant::Command::Base
  register "foo", "Runs the foo action on every VM"

  def execute
    # Only the values since its a name => VM hash.
    env.vms.values.each do |vm|
      vm.env.actions.run(:foo)
    end
  end
end
{% endhighlight %}

We can test it with the following:

{% highlight ruby %}
class MyCommandTest < Test::Unit::TestCase
  include Vagrant::TestHelpers

  def setup
    @env = vagrant_env
  end

  def test_my_command_runs_foo
    @env.vms.values.each do |vm|
      vm.env.actions.expects(:run).with(:foo).once
    end

    @env.cli("foo")
  end
end
{% endhighlight %}

Using method invocation expectations, this test verifies that every VM
has the foo sequence invoked.

Notice that we invoke the command using the `Environment#cli` method,
so we are able to invoke the command as if it were executed via the
actual command line.
