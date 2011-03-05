module Vagrant
  module Hosts
    autoload :Base,  'vagrant/hosts/base'
    autoload :BSD,   'vagrant/hosts/bsd'
    autoload :Linux, 'vagrant/hosts/linux'
  end
end
