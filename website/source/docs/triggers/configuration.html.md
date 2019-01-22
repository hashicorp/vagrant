---
layout: "docs"
page_title: "Vagrant Triggers Configuration"
sidebar_current: "triggers-configuration"
description: |-
  Documentation of various configuration options for Vagrant Triggers
---

# Configuration

Vagrant Triggers has a few options to define trigger behavior.

## Execution Order

The trigger config block takes two different operations that determine when a trigger
should fire:

* `before`
* `after`

These define _how_ the trigger behaves and determines when it should fire off during
the Vagrant life cycle. A simple example of a _before_ operation could look like:

```ruby
config.trigger.before :up do |t|
  t.info = "Bringing up your Vagrant guest machine!"
end
```

Triggers can be used with [_actions_](#actions) or [_commands_](#commands) as well,
but by default will be defined to run before or after a Vagrant guest.

## Trigger Options

The trigger class takes various options.

* `action` (symbol, array) - Expected to be a single symbol value, an array of symbols, or a _splat_ of symbols. The first argument that comes after either __before__ or __after__ when defining a new trigger. Can be any valid Vagrant command. It also accepts a special value `:all` which will make the trigger fire for every action. An action can be ignored with the `ignore` setting if desired. These are the valid action commands for triggers:

  - `destroy`
  - `halt`
  - `provision`
  - `reload`
  - `resume`
  - `suspend`
  - `up`

* `ignore` (symbol, array) - Symbol or array of symbols corresponding to the action that a trigger should not fire on.

* `info` (string) - A message that will be printed at the beginning of a trigger.

* `name` (string) - The name of the trigger. If set, the name will be displayed when firing the trigger.

* `on_error` (symbol) - Defines how the trigger should behave if it encounters an error. By default this will be `:halt`, but can be configured to ignore failures and continue on with `:continue`.

* `only_on` (string, regex, array) - Limit the trigger to these guests. Values can be a string or regex that matches a guest name.

* `ruby` (block) - A block of Ruby code to be executed on the host. The block accepts two arguments that can be used with your Ruby code: `env` and `machine`. These options correspond to the Vagrant environment used (note: these are not your shell's environment variables), and the Vagrant guest machine that the trigger is firing on. This option can only be a `Proc` type, which must be explicitly called out when using the hash syntax for a trigger.

    ```ruby
    ubuntu.trigger.after :up do |trigger|
      trigger.info = "More information"
      trigger.ruby do |env,machine|
        greetings = "hello there #{machine.id}!"
        puts greetings
      end
    end
    ```

* `run_remote` (hash) - A collection of settings to run a inline or remote script with on the guest. These settings correspond to the [shell provisioner](/docs/provisioning/shell.html).

* `run` (hash) - A collection of settings to run a inline or remote script on the host. These settings correspond to the [shell provisioner](/docs/provisioning/shell.html). However, at the moment the only settings `run` takes advantage of are:
  + `args`
  + `inline`
  + `path`

* `warn` (string) - A warning message that will be printed at the beginning of a trigger.

* `exit_codes` (integer, array) - A set of acceptable exit codes to continue on. Defaults to `0` if option is absent. For now only valid with the `run` option.

* `abort` (integer,boolean) - An option that will exit the running Vagrant process once the trigger fires. If set to `true`, Vagrant will use exit code 1. Otherwise, an integer can be provided and Vagrant will it as its exit code when aborting.

## Trigger Types

Optionally, it is possible to define a trigger that executes around Vagrant subcommands
and actions.

<div class="alert alert-warning">
  <strong>Warning!</strong> This feature is still experimental and may break or
  change in between releases. Use at your own risk.

  This feature was introduced at TODO FIX ME!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  and currently reqiures the experimental flag to be used. To explicitly enable this feature, you can set the experimental flag to:

  ```
  VAGRANT_EXPERIMENTAL="typed_triggers"
  ```

  TODO ADD DOCS PAGE!!!11
  `VAGRANT_EXPERIMENTAL` is an environment variable. For more information about this flag
  please visit the docs page for more info.

  Without this flag enabled, triggers with the `:type` option will be ignored.

  Vagrantfiles with the `:type` option for triggers will result in an error if
  used by older Vagrant versions.
</div>


A trigger can be one of two types:

* `type` (symbol) - Optional
  - `:action` - Action triggers run before or after a Vagrant action
  - `:command` - Command triggers run before or after a Vagrant subcommand

These types determine when and where a defined trigger will execute.

```ruby
config.trigger.after :destroy, type: :command do |t|
  t.warn = "Destroy command completed"
end
```

__Note:__ Triggers _without_ the type option will run before or after a
Vagrant guest. These most similarly align with the `:action` type, and by default
are classified internally as an action.

### Commands

Command typed triggers can be defined for any valid Vagrant subcommand. They will always
run before or after the subcommand.

```ruby
config.trigger.before :status, type: :command do |t|
  t.info = "Getting the status of your guests..."
end
```

The difference between this and the default behavior is that these triggers are
not attached to any specific guest, and will always run before or after the given
command.

### Actions

<div class="alert alert-warning">
  <strong>Advanced topic!</strong> This is an advanced topic for use only if
  you want to execute triggers around Vagrant actions. If you are just getting
  started with Vagrant and triggers, you may safely skip this section.
</div>

Actions in this case refer to the Vagrant class `#Action`, which is used internally
and in Vagrant plugins. These function similar to [action hooks](/docs/plugins/action-hooks.html)
and give the user the ability to run triggers any where within the life cycle of
a Vagrant run. For example, you could write up a Vagrant trigger that runs before
and after the provision action:

```ruby
config.trigger.before :provisioner_run, type: :action do |t|
  t.info = "Before the provision of the guest!!!"
end
```
