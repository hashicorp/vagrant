require_relative "../../omnibus"

module VagrantPlugins
  module Chef
    module Cap
      module Redhat
        module ChefInstall
          def self.chef_install(machine, project, version, channel, omnibus_url, options = {})
            machine.communicate.sudo <<-EOH.gsub(/^ {14}/, '')
              if command -v dnf; then
                dnf -y install curl
              else
                yum -y install curl
              fi
            EOH

            command = Omnibus.sh_command(project, version, channel, omnibus_url, options)
            machine.communicate.sudo(command)
          end
        end
      end
    end
  end
end
