require "json"

require "vagrant/util/powershell"

module VagrantPlugins
  module HostWindows
    module Cap
      class LoadHostIPs
        def self.load_host_ips(env)
          script_path = File.expand_path("../../scripts/host_info.ps1", __FILE__)
          r = Vagrant::Util::PowerShell.execute(script_path)
          if r.exit_code != 0
            raise Errors::PowershellError,
              script: script_path,
              stderr: r.stderr
          end

          JSON.parse(r.stdout)["ip_addresses"]
        end
      end
    end
  end
end
