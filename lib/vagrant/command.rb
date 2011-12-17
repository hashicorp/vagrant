module Vagrant
  module Command
    autoload :Base,      'vagrant/command/base'

    autoload :Destroy, 'vagrant/command/destroy'
    autoload :Up, 'vagrant/command/up'
  end
end
