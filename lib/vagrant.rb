# This file is load before RubyGems are loaded, and allow us to actually
# resolve plugin dependencies and load the proper versions of everything.

ENV["VAGRANT_INSTALLER_EMBEDDED_DIR"] = "/Applications/Vagrant/embedded"

if defined?(Bundler)
  require "bundler/shared_helpers"
  if Bundler::SharedHelpers.in_bundle?
    puts "Vagrant appears to be running in a Bundler environment. Plugins"
    puts "will not be loaded and plugin commands are disabled."
    puts
    ENV["VAGRANT_NO_PLUGINS"] = "1"
  end
end

require_relative "vagrant/shared_helpers"

if Vagrant.plugins_enabled?
  # Initialize Bundler before we load _any_ RubyGems.
  require_relative "vagrant/bundler"
  require_relative "vagrant/plugin_manager"
  Vagrant::Bundler.instance.init!(Vagrant::Plugin::Manager.instance.installed_plugins)
end

# Initialize Vagrant now that our Gem paths are setup
require "vagrant/init"

# If we have plugins enabled, then load those
Bundler.require(:default) if Vagrant.plugins_enabled?
