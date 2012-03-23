---
layout: extending
title: Extending Vagrant - Middleware

current: Middleware
---
# Middleware

Believe it or not, [middleware](http://en.wikipedia.org/wiki/Middleware) based architecture
powers most of the functionality behind Vagrant. The reasoning for this is middlewares are
self-contained pieces of functionality which can be stacked and ordered to create larger
pieces of functionality. For example, the `vagrant up` command is built of up over 10 middlewares
such as "boot," "import," "forward ports," etc.

Vagrant calls middlewares "actions" and a stack of middlewares an "action sequence."
(But you may also just call them middleware and middleware stacks, they're mostly
called the other names for histortical purposes)

Middleware stacks can be _registered_ under specific names, which can then be
referenced later to add new functionality or remove existing functionality.

## Creating a Middleware

Middlewares are simply a class. First, a sample middleware below, then I'll
explain the various parts of it:

{% highlight ruby %}
class SayHelloMiddleware
  def initialize(app, env)
    @app = app
  end

  def call(env)
    env[:ui].info "Hello!"
    @app.call(env)
  end
end
{% endhighlight %}

The middleware is initialized with an `app` and an `env`. The `app` is the next
middleware in the chain, and the `env` is a hash which is passed up and down the
middleware stack.

The method `call` is called to kick off the middleware, and the middleware
is expected to call `call` on the next middleware in the sequence (the `app`
variable passed in to the initializer). Functionality can be added anywhere
around the call to the next middleware.

The `env` variable is an instance of `Vagrant::Action::Environment` which is
a hash. It is always pre-loaded with the various accessors of `Vagrant::Environment`,
which is why `env["ui"]` can be accessed on the hash.

## Running a Middleware

Once the middleware is built, it can be run on the environment using the
`env.action_runner` object. An example is shown below, which assumes that the
Vagrant environment object is already loaded into `env`:

{% highlight ruby %}
env.action_runner.run(SayHelloMiddleware)
{% endhighlight %}

That's it! This will run the middleware given.

Note that middleware usually wants to modify a specific VM or expects
to run in the context of a specific VM. The `VM` objects also have a
`run_action` method which will run a middleware with the `:vm` item
in the middleware environment set to the VM object. For example, to
run a middleware in the context of the primary VM:

{% highlight ruby %}
env.primary_vm.run_action(SayHelloMiddleware)
{% endhighlight %}

## Creating a Middleware Stack

There are many benefits to creating a middleware _stack_:

* Multiple middlewares can be used in a sequence
* The stack can be registered so it can be modified later
* Existing registered stacks can be used in a sequence

And creating a stack isn't much harder than just creating a regular
old middleware. To turn the above middleware and register it as a stack:

{% highlight ruby %}
say_hello = Vagrant::Action::Builder.new do
  use SayHelloMiddleware
end

Vagrant.actions.register :say_hello, say_hello
{% endhighlight %}

First, we use `Vagrant::Action::Builder` to build up a sequence of
middlewares. The `use` method adds that middleware class to the
sequence.

Then, by calling `Vagrant.actions.register`, the builder instance is
registered under the name `:say_hello`.

Finally, running this stack is equally easy:

{% highlight ruby %}
env.action_runner.run(:say_hello)
{% endhighlight %}

## Modifying an Existing Middleware Stack

Once a middleware stack is registered, it can be easily modified.
One registered middleware stack is `up`. For the purpose of this example,
let's say we want to replace the `ForwardPort` middleware with our `SayHello`
middleware (note that in practice this is a _really_ bad idea). An example
of this is shown below:

{% highlight ruby %}
Vagrant.actions[:up].swap(Vagrant::Action::VM::ForwardPort, SayHello)
{% endhighlight %}

Easy, isn't it? Now if you were to run `vagrant up`, instead of forwarding
ports, it would say hello!

To see all the available methods to manipulate a middleware stack,
see the documentation for `Vagrant::Action::Builder`.

