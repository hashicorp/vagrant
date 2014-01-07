---
page_title: "vagrant plugin - Command-Line Interface"
sidebar_current: "cli-plugin"
---

# Plugin

**Command: `vagrant plugin`**

This is the command used to manage [plugins](/v2/plugins/index.html).

The main functionality of this command is exposed via another level
of subcommands:

* `install`
* `license`
* `list`
* `uninstall`
* `update`

# Plugin Install

**Command: `vagrant plugin install <name>...`**

This installs a plugin with the given name or file path. If the name
is not a path to a file, then the plugin is installed from remote
repositories, usually [RubyGems](http://rubygems.org). This command will
also update a plugin if it is already installed, but you can also use
`vagrant plugin update` for that.

If multiple names are specified, multiple plugins will be installed. If
flags are given below, the flags will apply to _all_ plugins being installed
by the current command invocation.

This command accepts optional command-line flags:

* `--entry-point ENTRYPOINT` - By default, installed plugins are loaded
  internally by loading an initialization file of the same name as the plugin.
  Most of the time, this is correct. If the plugin you're installing has
  another entrypoint, this flag can be used to specify it.

* `--plugin-source SOURCE` - Adds a source from which to fetch a plugin. Note
  that this doesn't only affect the single plugin being installed, by all future
  plugin as well. This is a limitation of the underlying plugin installer
  Vagrant uses.

* `--plugin-version VERSION` - The version of the plugin to install. By default,
  this command will install the latest version. You can constrain the version
  using this flag. You can set it to a specific version, such as "1.2.3" or
  you can set it to a version contraint, such as "> 1.0.2". You can set it
  to a more complex constraint by comma-separating multiple constraints:
  "> 1.0.2, < 1.1.0" (don't forget to quote these on the command-line).

# Plugin License

**Command: `vagrant plugin license <name> <license-file>`**

This command installs a license for a proprietary Vagrant plugin,
such as the [VMware Fusion provider](/v2/vmware/index.html).

# Plugin List

**Command: `vagrant plugin list`**

This lists all installed plugins and their respective installed versions.
If a version constraint was specified for a plugin when installing it, the
constraint will be listed as well. Other plugin-specific information may
be shown, too.

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
