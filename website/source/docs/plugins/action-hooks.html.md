---
layout: "docs"
page_title: "Plugin Development Basics - Action Hooks"
sidebar_current: "plugins-action-hooks"
description: |-
  Action hooks provide ways to interact with Vagrant at a very low level by
  injecting middleware in various phases of Vagrant's lifecycle. This is an
  advanced option, even for plugin development.
---

# Action Hooks

Action hooks provide ways to interact with Vagrant at a very low level by
injecting middleware in various phases of Vagrant's lifecycle. This is an
advanced option, even for plugin development.

<div class="alert alert-warning">
  <strong>Warning: Advanced Topic!</strong> Developing plugins is an
  advanced topic that only experienced Vagrant users who are reasonably
  comfortable with Ruby should approach.
</div>


## Public Action Hooks

The following action hooks are available in the core of Vagrant. Please note
that this list is not exhaustive and additional hooks can be added via plugins.

- `environment_plugins_loaded` - called after the plugins have been loaded,
  but before the configurations, provisioners, providers, etc. are loaded.


- `environment_load` - called after the environment and all configurations are
  fully loaded.


- `environment_unload` - called after the environment is done being used. The
  environment should not be used in this hook.


- `machine_action_boot` - called after the hypervisor has reported the machine
  was booted.


- `machine_action_config_validate` - called after all `Vagrantfile`s have been
  loaded, merged, and validated.


- `machine_action_destroy` - called after the hypervisor has reported the
  virtual machine is down.


- `machine_action_halt` - called after the hypervision has moved the machine
  into a halted state (usually "stopped" but not "terminated").


- `machine_action_package` - called after Vagrant has successfully packaged a
  new box.


- `machine_action_provision` - called after all provisioners have executed.


- `machine_action_read_state` - called after Vagrant has loaded state from
  disk and the hypervisor.


- `machine_action_reload` - called after a virtual machine is reloaded (varies
  by hypervisor).


- `machine_action_resume` - called after a virtual machine is moved from the
  halted to up state.


- `machine_action_run_command` - called after a command is executed on the
  machine.


- `machine_action_ssh` - called after an SSH connection has been established.


- `machine_action_ssh_run` - called after an SSH command is executed.


- `machine_action_start` - called after the machine has been started.


- `machine_action_suspend` - called after the machine has been suspended.


- `machine_action_sync_folders` - called after synced folders have been set up.


- `machine_action_up` - called after the machine has entered the up state.


## Private API

You may find additional action hooks if you browse the Vagrant source code, but
only the list of action hooks here are guaranteed to persist between Vagrant
releases. Please do not rely on the internal API as it is subject to change
without notice.
