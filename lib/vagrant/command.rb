module Vagrant
  module Command
    autoload :Base,      'vagrant/command/base'

    autoload :Destroy, 'vagrant/command/destroy'
    autoload :Halt, 'vagrant/command/halt'
    autoload :Up, 'vagrant/command/up'
  end
end
