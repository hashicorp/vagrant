# This file is load before RubyGems are loaded, and allow us to actually
# resolve plugin dependencies and load the proper versions of everything.

if defined?(Vagrant)
  raise "vagrant is somehow already loaded. bug."
end

ENV["VAGRANT_INSTALLER_EMBEDDED_DIR"] = "/Applications/Vagrant/embedded"

# Initialize Bundler before we load _any_ RubyGems.
require_relative "vagrant/bundler"
require_relative "vagrant/plugin_manager"
Vagrant::Bundler.instance.init!(Vagrant::PluginManager.plugins)

# Initialize Vagrant first, then load the remaining dependencies
require "vagrant/init"
Bundler.require(:default)
