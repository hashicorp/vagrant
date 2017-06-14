require_relative "../../omnibus"

module VagrantPlugins
  module Chef
    module Cap
      module FreeBSD
        module ChefInstall
          def self.chef_install(machine, project, version, channel, omnibus_url, options = {})
            machine.communicate.sudo("pkg install -y -qq curl bash")

            command = Omnibus.sh_command(project, version, channel, omnibus_url, options)
            machine.communicate.sudo(command)
          end
        end
      end
    end
  end
end
