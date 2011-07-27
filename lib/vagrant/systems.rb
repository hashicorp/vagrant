# These can't be autoloaded because they have to register functionality
# with Vagrant core.
require 'vagrant/systems/base'
require 'vagrant/systems/freebsd'
require 'vagrant/systems/linux'
require 'vagrant/systems/solaris'

require 'vagrant/systems/debian'
require 'vagrant/systems/gentoo'
require 'vagrant/systems/redhat'
require 'vagrant/systems/suse'
require 'vagrant/systems/ubuntu'
require 'vagrant/systems/arch'
