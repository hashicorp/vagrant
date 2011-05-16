# These aren't autoloaded because they have to register things such
# as configuration classes right away with Vagrant.
require 'vagrant/provisioners/base'
require 'vagrant/provisioners/chef'
require 'vagrant/provisioners/chef_server'
require 'vagrant/provisioners/chef_solo'
require 'vagrant/provisioners/puppet'
require 'vagrant/provisioners/puppet_server'
require 'vagrant/provisioners/shadow_puppet'
require 'vagrant/provisioners/shell'
