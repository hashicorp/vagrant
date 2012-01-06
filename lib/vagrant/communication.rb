module Vagrant
  module Communication
    autoload :Base, 'vagrant/communication/base'

    autoload :SSH,  'vagrant/communication/ssh'
  end
end
