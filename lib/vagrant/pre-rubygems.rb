# This file is to be loaded _before_ any RubyGems are loaded. This file
# initializes the Bundler context so that Vagrant and its associated plugins
# can load properly, and then execs out into Vagrant again.

if defined?(Bundler)
  require "bundler/shared_helpers"
  if Bundler::SharedHelpers.in_bundle?
    puts "Vagrant appears to be running in a Bundler environment. Your "
    puts "existing Gemfile will be used. Vagrant will not auto-load any plugins."
    puts "You must load any plugins you want manually in a Vagrantfile. You can"
    puts "force Vagrant to take over with VAGRANT_FORCE_BUNDLER."
    puts
  end
end

require_relative "bundler"
require_relative "plugin/manager"
require_relative "shared_helpers"

plugins = Vagrant::Plugin::Manager.instance.installed_plugins
Vagrant::Bundler.instance.init!(plugins)

ENV["VAGRANT_INTERNAL_BUNDLERIZED"] = "1"
Kernel.exec("vagrant", *ARGV)
