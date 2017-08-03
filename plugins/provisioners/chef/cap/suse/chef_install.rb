require_relative "../../omnibus"

module VagrantPlugins
  module Chef
    module Cap
      module Suse
        module ChefInstall
          def self.chef_install(machine, project, version, channel, omnibus_url, options = {})
            unless curl?(machine)
              machine.communicate.sudo("zypper -n -q update")
              machine.communicate.sudo("zypper -n -q install curl")
            end

            command = Omnibus.sh_command(project, version, channel, omnibus_url, options)
            machine.communicate.sudo(command)
          end

          protected

          def self.curl?(machine)
            machine.communicate.test("/usr/bin/which -s curl")
          end
        end
      end
    end
  end
end
