#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------
module VagrantPlugins
  module HyperV
    module Action
      class Provision < Vagrant::Action::Builtin::Provision

        # Override this method from core vagrant, here we branch out the provision for windows
        def run_provisioner(env)
          if env[:machine].provider_config.guest == :windows
            case env[:provisioner]
            when VagrantPlugins::Shell::Provisioner
              WindowsProvisioner::Shell.new(env).provision
            when VagrantPlugins::Puppet::Provisioner::Puppet
              WindowsProvisioner::Puppet.new(env).provision
            end
          else
            env[:provisioner].provision
          end
        end
      end
    end
  end
end
