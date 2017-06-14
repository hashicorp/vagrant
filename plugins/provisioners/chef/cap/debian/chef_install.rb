require_relative "../../omnibus"

module VagrantPlugins
  module Chef
    module Cap
      module Debian
        module ChefInstall
          def self.chef_install(machine, project, version, channel, omnibus_url, options = {})
            machine.communicate.sudo("apt-get update -y -qq")
            machine.communicate.sudo("apt-get install -y -qq curl")

            command = Omnibus.sh_command(project, version, channel, omnibus_url, options)
            machine.communicate.sudo(command)
          end
        end
      end
    end
  end
end
