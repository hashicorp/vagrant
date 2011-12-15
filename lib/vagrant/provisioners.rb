# These aren't autoloaded because they have to register things such
# as configuration classes right away with Vagrant.
module Vagrant
  module Provisioners
    autoload :Base,         'vagrant/provisioners/base'
    autoload :ChefSolo,     'vagrant/provisioners/chef_solo'
    autoload :ChefClient,   'vagrant/provisioners/chef_client'
    autoload :Puppet,       'vagrant/provisioners/puppet'
    autoload :PuppetServer, 'vagrant/provisioners/puppet_server'
    autoload :Shell,        'vagrant/provisioners/shell'
  end
end
