---
layout: "docs"
page_title: "Vagrant Triggers Configuration"
sidebar_current: "triggers-configuration"
description: |-
  Documentation of various configuration options for Vagrant Triggers
---

# Configuration

Vagrant Triggers has a few options to define trigger behavior.

## Options

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
