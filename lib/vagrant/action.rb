require 'vagrant/action/builder'

module Vagrant
  module Action
    autoload :Environment, 'vagrant/action/environment'
    autoload :Runner,      'vagrant/action/runner'
    autoload :Warden,      'vagrant/action/warden'

    module Box
      autoload :Add,       'vagrant/action/box/add'
      autoload :Download,  'vagrant/action/box/download'
      autoload :Verify,    'vagrant/action/box/verify'
    end

    # Builtin contains middleware classes that are shipped with Vagrant-core
    # and are thus available to all plugins as a "standard library" of sorts.
    module Builtin
      autoload :Call, "vagrant/action/builtin/call"
      autoload :Confirm, "vagrant/action/builtin/confirm"
      autoload :EnvSet,  "vagrant/action/builtin/env_set"
      autoload :SSHExec, "vagrant/action/builtin/ssh_exec"
      autoload :SSHRun, "vagrant/action/builtin/ssh_run"
    end

    module General
      autoload :Package,  'vagrant/action/general/package'
      autoload :Validate, 'vagrant/action/general/validate'
    end
  end
end
