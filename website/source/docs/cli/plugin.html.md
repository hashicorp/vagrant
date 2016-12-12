---
layout: "docs"
page_title: "vagrant plugin - Command-Line Interface"
sidebar_current: "cli-plugin"
description: |-
  The "vagrant plugin" command is used to manage Vagrant plugins including
  installing, uninstalling, and license management.
---

# Plugin

**Command: `vagrant plugin`**

This is the command used to manage [plugins](/docs/plugins/).

The main functionality of this command is exposed via another level
of subcommands:

* [`expunge`](#plugin-expunge)
* [`install`](#plugin-install)
* [`license`](#plugin-license)
* [`list`](#plugin-list)
* [`repair`](#plugin-repair)
* [`uninstall`](#plugin-uninstall)
* [`update`](#plugin-update)

# Plugin Expunge

**Command: `vagrant plugin expunge`**

This removes all user installed plugin information. All plugin gems, their
dependencies, and the `plugins.json` file are removed. This command
provides a simple mechanism to fully remove all user installed custom plugins.

When upgrading Vagrant it may be required to reinstall plugins due to
an internal incompatibility. The expunge command can help make that process
easier by attempting to automatically reinstall currently configured
plugins:

```shell
# Delete all plugins and reinstall
$ vagrant plugin expunge --reinstall
```

This command accepts optional command-line flags:

* `--force` - Do not prompt for confirmation prior to removal
* `--reinstall` - Attempt to reinstall plugins after removal

# Plugin Install

**Command: `vagrant plugin install <name>...`**

This installs a plugin with the given name or file path. If the name
is not a path to a file, then the plugin is installed from remote
repositories, usually [RubyGems](https://rubygems.org). This command will
also update a plugin if it is already installed, but you can also use
`vagrant plugin update` for that.

```shell
# Installing a plugin from a known gem source
$ vagrant plugin install my-plugin

# Installing a plugin from a local file source
$ vagrant plugin install /path/to/my-plugin.gem
```

If multiple names are specified, multiple plugins will be installed. If
flags are given below, the flags will apply to _all_ plugins being installed
by the current command invocation.

If the plugin is already installed, this command will reinstall it with
the latest version available.

This command accepts optional command-line flags:

* `--entry-point ENTRYPOINT` - By default, installed plugins are loaded
  internally by loading an initialization file of the same name as the plugin.
  Most of the time, this is correct. If the plugin you are installing has
  another entrypoint, this flag can be used to specify it.

* `--plugin-clean-sources` - Clears all sources that have been defined so
  far. This is an advanced feature. The use case is primarily for corporate
  firewalls that prevent access to RubyGems.org.

* `--plugin-source SOURCE` - Adds a source from which to fetch a plugin. Note
  that this does not only affect the single plugin being installed, by all future
  plugin as well. This is a limitation of the underlying plugin installer
  Vagrant uses.

* `--plugin-version VERSION` - The version of the plugin to install. By default,
  this command will install the latest version. You can constrain the version
  using this flag. You can set it to a specific version, such as "1.2.3" or
  you can set it to a version constraint, such as "> 1.0.2". You can set it
  to a more complex constraint by comma-separating multiple constraints:
  "> 1.0.2, < 1.1.0" (do not forget to quote these on the command-line).

# Plugin License

**Command: `vagrant plugin license <name> <license-file>`**

This command installs a license for a proprietary Vagrant plugin,
such as the [VMware Fusion provider](/docs/vmware).

# Plugin List

**Command: `vagrant plugin list`**

This lists all installed plugins and their respective installed versions.
If a version constraint was specified for a plugin when installing it, the
constraint will be listed as well. Other plugin-specific information may
be shown, too.

# Plugin Repair

Vagrant may fail to properly initialize user installed custom plugins. This can
be caused my improper plugin installation/removal, or by manual manipluation of
plugin related files like the `plugins.json` data file. Vagrant can attempt
to automatically repair the problem.

If automatic repair is not successful, refer to the [expunge](#plugin-expunge)
command

# Plugin Uninstall

**Command: `vagrant plugin uninstall <name> [<name2> <name3> ...]`**

This uninstalls the plugin with the given name. Any dependencies of the
plugin will also be uninstalled assuming no other plugin needs them.

If multiple plugins are given, multiple plugins will be uninstalled.

# Plugin Update

**Command: `vagrant plugin update [<name>]`**

This updates the plugins that are installed within Vagrant. If you specified
version constraints when installing the plugin, this command will respect
those constraints. If you want to change a version constraint, re-install
the plugin using `vagrant plugin install`.

If a name is specified, only that single plugin will be updated. If a
name is specified of a plugin that is not installed, this command will not
install it.
