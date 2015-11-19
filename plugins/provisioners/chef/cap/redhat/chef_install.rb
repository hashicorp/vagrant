require_relative "../../omnibus"

module VagrantPlugins
  module Chef
    module Cap
      module Redhat
        module ChefInstall
          def self.chef_install(machine, project, version, channel, options = {})
            if dnf?(machine)
              machine.communicate.sudo("dnf install -y -q curl")
            else
              machine.communicate.sudo("yum install -y -q curl")
            end

            command = Omnibus.sh_command(project, version, channel, options)
            machine.communicate.sudo(command)
          end

          protected

          def self.dnf?(machine)
            machine.communicate.test("/usr/bin/which -s dnf")
          end
        end
      end
    end
  end
end
