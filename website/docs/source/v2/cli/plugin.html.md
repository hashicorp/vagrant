---
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

# Plugin Install

**Command: `vagrant plugin install <name>`**

This installs a plugin with the given name or file path. If the name
is not a path to a file, then the plugin is installed from remote
repositories, usually [RubyGems](http://rubygems.org).

# Plugin License

**Command: `vagrant plugin license <name> <license-file>`**

This command installs a license for a proprietary Vagrant plugin,
such as the [VMware Fusion provider](/v2/vmware/index.html).

# Plugin List

**Command: `vagrant plugin list`**

This lists all installed plugins and their respective versions.

# Plugin Uninstall

**Command: `vagrant plugin uninstall <name>`**

This uninstalls the plugin with the given name. Any dependencies of the
plugin will also be uninstalled assuming no other plugin needs them.
