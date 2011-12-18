module Vagrant
  module Command
    autoload :Base,      'vagrant/command/base'

    autoload :Destroy, 'vagrant/command/destroy'
    autoload :Halt, 'vagrant/command/halt'
    autoload :Package, 'vagrant/command/package'
    autoload :Provision, 'vagrant/command/provision'
    autoload :Reload, 'vagrant/command/reload'
    autoload :Resume, 'vagrant/command/resume'
    autoload :SSH, 'vagrant/command/ssh'
    autoload :SSHConfig, 'vagrant/command/ssh_config'
    autoload :Status, 'vagrant/command/status'
    autoload :Suspend, 'vagrant/command/suspend'
    autoload :Up, 'vagrant/command/up'
  end
end
