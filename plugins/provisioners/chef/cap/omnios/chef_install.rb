require_relative "../../omnibus"

module VagrantPlugins
  module Chef
    module Cap
      module OmniOS
        module ChefInstall
          def self.chef_install(machine, project, version, channel, omnibus_url, options = {})
            su = machine.config.solaris.suexec_cmd

            machine.communicate.execute("#{su} pkg list --no-refresh web/curl > /dev/null 2>&1 || pkg install -q --accept web/curl")

            command = Omnibus.sh_command(project, version, channel, omnibus_url, options)
            machine.communicate.execute("#{su} #{command}")
          end
        end
      end
    end
  end
end
