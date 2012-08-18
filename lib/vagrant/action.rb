require 'vagrant/action/builder'

module Vagrant
  module Action
    autoload :Environment, 'vagrant/action/environment'
    autoload :Runner,      'vagrant/action/runner'
    autoload :Warden,      'vagrant/action/warden'

    # Builtin contains middleware classes that are shipped with Vagrant-core
    # and are thus available to all plugins as a "standard library" of sorts.
    module Builtin
      autoload :BoxAdd,  "vagrant/action/builtin/box_add"
      autoload :Call,    "vagrant/action/builtin/call"
      autoload :Confirm, "vagrant/action/builtin/confirm"
      autoload :EnvSet,  "vagrant/action/builtin/env_set"
      autoload :SSHExec, "vagrant/action/builtin/ssh_exec"
      autoload :SSHRun,  "vagrant/action/builtin/ssh_run"
    end

    module General
      autoload :Package,  'vagrant/action/general/package'
      autoload :Validate, 'vagrant/action/general/validate'
    end

    def self.action_box_add
      Builder.new.tap do |b|
        b.use Builtin::BoxAdd
      end
    end
  end
end
