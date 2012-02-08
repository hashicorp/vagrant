module Vagrant
  module Command
    autoload :Base,      'vagrant/command/base'

    autoload :Box,          'vagrant/command/box'
    autoload :BoxAdd,       'vagrant/command/box_add'
    autoload :BoxRemove,    'vagrant/command/box_remove'
    autoload :BoxRepackage, 'vagrant/command/box_repackage'
    autoload :BoxList,      'vagrant/command/box_list'
    autoload :Destroy,      'vagrant/command/destroy'
    autoload :Gem,          'vagrant/command/gem'
    autoload :Halt,         'vagrant/command/halt'
    autoload :Init,         'vagrant/command/init'
    autoload :Package,      'vagrant/command/package'
    autoload :Provision,    'vagrant/command/provision'
    autoload :Reload,       'vagrant/command/reload'
    autoload :Resume,       'vagrant/command/resume'
    autoload :SSH,          'vagrant/command/ssh'
    autoload :SSHConfig,    'vagrant/command/ssh_config'
    autoload :Status,       'vagrant/command/status'
    autoload :Suspend,      'vagrant/command/suspend'
    autoload :Up,           'vagrant/command/up'
  end
end
