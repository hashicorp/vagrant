require_relative "../../omnibus"

module VagrantPlugins
  module Chef
    module Cap
      module Debian
        module ChefInstall
          def self.chef_install(machine, version, prerelease, download_path)
            machine.communicate.sudo("apt-get update -y -qq")
            machine.communicate.sudo("apt-get install -y -qq curl")

            command = Omnibus.build_command(version, prerelease, download_path)
            machine.communicate.sudo(command)
          end
        end
      end
    end
  end
end
