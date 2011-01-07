# These can't be autoloaded because they have to register functionality
# with Vagrant core.
require 'vagrant/systems/base'
require 'vagrant/systems/linux'
require 'vagrant/systems/solaris'
