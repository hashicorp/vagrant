---
layout: v2_documentation
title: Documentation - Writing Plugins - Action Hooks

section: plugins
current: Action Hooks
---
# Action Hooks

[Middleware-based](http://en.wikipedia.org/wiki/Middleware)
architecture powers most of the functionality behind Vagrant. Action hooks
provide a way to hook into these stacks of middleware in order to add
custom functionality or to change behavior.

Vagrant forms middleware stacks, known as "action sequences" in order to
do any VM manipulation. For example, when you run `vagrant up`, `vagrant reload`,
`vagrant halt`, etc. action sequences are used behind the scenes. Action sequences
allow a complicated process to be broken down into small composable pieces
that are easier to reason about.

## Example: Create a File in a VM

We'll show a quick example followed by an explanation of the individual
components in order to show how action hooks work.

{% highlight ruby %}
class Plugin < Vagrant.plugin("1")
  name "create-a-file"

  action_hook(:up) do |seq|
    create_file = lambda do |env|
      env[:vm].ssh.execute("touch ~/foo")
    end

    seq.insert_after(Vagrant::Action::VM::Boot, CreateFile)
  end
end
{% endhighlight %}

Ignoring the boilerplate of a plugin definition, the only new thing is
the component registered with `action_hook`. The first parameter to
`action_hook` specifies the named action sequence that you want to hook
into. A block is then passed which takes the sequence itself as a parameter.
The middleware sequences [exposes many methods](#)
you can use to manipulate it, inserting your own middleware actions.

In the case of the above example, we use a lambda as a basic action. Action
creation will be covered later, but for now you should be able to tell that
this will be executed after the `Boot` action.

## Actions

Actions are what compose an action sequence. An action can either be a simple
lambda or if you need more power or organization, it can be a Ruby class. Lambda
based actions take a single parameter `env`, which is the environment state
bag passed to all actions. The state bag is a hash that contains state. The
exact contents depend on what actions ran before your action was called. This
state bag is what contains the VM being manipulated, configuration, etc.

If you want to use a class as an action, it'll end up looking like the
following:

{% highlight ruby %}
class Action
  def initialize(app, env)
    @app = app
  end

  def call(env)
    @app.call(env)
  end
end
{% endhighlight %}

An `initialize` method must be made which takes the given two arguments.
`app` is the next action to run, so store it away. `env` is the state bag
so that you can initialize it with some data before any actions are run,
if you want.

`call` is the method called when it is time for your action to do something.
It takes `env` again which is the state bag which is now populated with
whatever previous actions put in it. When you're ready to call the next action,
call `@app.call(env)`. This allows you to do pre and post actions depending
on whether its before or after the `@app.call`.
