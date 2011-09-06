module Vagrant
  module Hosts
    autoload :Base,  'vagrant/hosts/base'
    autoload :Arch,  'vagrant/hosts/arch'
    autoload :BSD,   'vagrant/hosts/bsd'
    autoload :Fedora, 'vagrant/hosts/fedora'
    autoload :Linux, 'vagrant/hosts/linux'
  end
end
