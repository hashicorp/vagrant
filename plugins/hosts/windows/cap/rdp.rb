require "pathname"
require "tmpdir"

require "vagrant/util/subprocess"

module VagrantPlugins
  module HostWindows
    module Cap
      class RDP
        def self.rdp_client(env, rdp_info)
          # Setup password
          cmdKeyArgs = [
            "/add:#{rdp_info[:host]}:#{rdp_info[:port]}",
            "/user:#{rdp_info[:username]}",
            "/pass:#{rdp_info[:password]}",
          ]
          Vagrant::Util::Subprocess.execute("cmdkey", *cmdKeyArgs)

          # Build up the args to mstsc
          args = ["/v:#{rdp_info[:host]}:#{rdp_info[:port]}"]
          if rdp_info[:extra_args]
            args = rdp_info[:extra_args] + args
          end
          # Launch it
          Vagrant::Util::Subprocess.execute("mstsc", *args)
        end
      end
    end
  end
end
