module Vagrant
  module Command
    autoload :Base,      'vagrant/command/base'
    autoload :GroupBase, 'vagrant/command/group_base'
    autoload :Helpers,   'vagrant/command/helpers'
    autoload :NamedBase, 'vagrant/command/named_base'
  end
end

# The built-in commands must always be loaded
require 'vagrant/command/box'
require 'vagrant/command/destroy'
require 'vagrant/command/halt'
require 'vagrant/command/init'
require 'vagrant/command/package'
require 'vagrant/command/provision'
require 'vagrant/command/reload'
require 'vagrant/command/resume'
require 'vagrant/command/ssh'
require 'vagrant/command/ssh_config'
require 'vagrant/command/status'
require 'vagrant/command/suspend'
require 'vagrant/command/up'
require 'vagrant/command/upgrade_to_060'
require 'vagrant/command/version'
