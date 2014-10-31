require_relative "../../omnibus"

module VagrantPlugins
  module Chef
    module Cap
      module Redhat
        module ChefInstall
          def self.chef_install(machine, version, prerelease)
            machine.communicate.sudo("yum install -y -q curl")

            command = Omnibus.build_command(version, prerelease)
            machine.communicate.sudo(command)
          end
        end
      end
    end
  end
end
