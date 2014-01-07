# This file is to be loaded _before_ any RubyGems are loaded. This file
# initializes the Bundler context so that Vagrant and its associated plugins
# can load properly, and then execs out into Vagrant again.

if defined?(Bundler)
  require "bundler/shared_helpers"
  if Bundler::SharedHelpers.in_bundle?
    if ENV["VAGRANT_FORCE_PLUGINS"]
      puts "Vagrant appears to be running in a Bundler environment. Normally,"
      puts "plugins would not be loaded, but VAGRANT_FORCE_PLUGINS is enabled,"
      puts "so they will be."
      puts
    else
      puts "Vagrant appears to be running in a Bundler environment. Plugins"
      puts "will not be loaded and plugin commands are disabled."
      puts
      ENV["VAGRANT_NO_PLUGINS"] = "1"
    end
  end
end

require_relative "bundler"
require_relative "plugin/manager"
require_relative "shared_helpers"

plugins = Vagrant::Plugin::Manager.instance.installed_plugins
Vagrant::Bundler.instance.init!(plugins)

ENV["VAGRANT_INTERNAL_BUNDLERIZED"] = "1"
Kernel.exec("vagrant", *ARGV)
