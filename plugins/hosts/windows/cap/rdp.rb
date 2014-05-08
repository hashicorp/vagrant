require "tempfile"

require "vagrant/util/powershell"

module VagrantPlugins
  module HostWindows
    module Cap
      class RDP
        def self.rdp_client(env, rdp_info)
          config = nil
          opts   = {
            "drivestoredirect:s"       => "*",
            "full address:s"           => "#{rdp_info[:host]}:#{rdp_info[:port]}",
            "prompt for credentials:i" => "1",
            "username:s"               => rdp_info[:username],
          }

          # Create the ".rdp" file
          config = Tempfile.new(["vagrant-rdp", ".rdp"])
          opts.each do |k, v|
            config.puts("#{k}:#{v}")
          end
          config.close

          # Build up the args to mstsc
          args = [config.path]
          if rdp_info[:extra_args]
            args = rdp_info[:extra_args] + args
          end

          # Launch it
          Vagrant::Util::PowerShell.execute("mstsc", *args)
        ensure
          config.close if config
        end
      end
    end
  end
end
