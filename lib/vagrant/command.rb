module Vagrant
  module Command
    autoload :Base,      'vagrant/command/base'

    autoload :Destroy, 'vagrant/command/destroy'
    autoload :Halt, 'vagrant/command/halt'
    autoload :Provision, 'vagrant/command/provision'
    autoload :Reload, 'vagrant/command/reload'
    autoload :Resume, 'vagrant/command/resume'
    autoload :Up, 'vagrant/command/up'
  end
end
