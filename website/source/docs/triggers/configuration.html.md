---
layout: "docs"
page_title: "Vagrant Triggers Configuration"
sidebar_current: "triggers-configuration"
description: |-
  Documentation of various configuration options for Vagrnat Triggers
---

# Configuration

Vagrant Triggers has a few various options that can be set which define how the
trigger should behave.

## Options

The trigger class takes various options.

* `action` (symbol, array) - Expected to be a single symbol value, an array of symbols, or a _splat_ of symbols. The first argument that comes after either __before__ or __after__ when defining a new trigger. Can be any valid Vagrant command. It also accepts a special value `:all` which will make the trigger fire for every action. An action can be ignored with the `ignore` setting if desired.

* `ignore` (symbol, array) - Symbol or array of symbols corresponding to the action that a trigger should not fire on.

* `info` (string) - A message that will be printed at the beginning of a trigger.

* `name` (string) - The name of the trigger. If set, the name will be displayed when firing the trigger.

* `on_error` (symbol) - Defines how the trigger should behave if it encounters an error. By default this will be `:halt`, but can be configured to ignore failures and continue on with `:continue`.

* `only_on` (string, regex, array) - Guest or guests to be ignored on the defined trigger. Values can be a string or regex that matches a guest name.

* `run_remote` (hash) - A collection of settings to run a inline or remote script with on the guest. These settings correspond to the [shell provosioner](/docs/provisioning/shell.html).

* `run` (hash) - A collection of settings to run a inline or remote script with on the host. These settings correspond to the [shell provosioner](/docs/provisioning/shell.html). However, at the moment the only settings `run` takes advantage of are:
  + `args`
  + `inline`
  + `path`

* `warn` (string) - A warning message that will be printed at the beginning of a trigger.
