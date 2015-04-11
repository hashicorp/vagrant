require "pathname"
require "tmpdir"

require "vagrant/util/subprocess"

module VagrantPlugins
  module HostWindows
    module Cap
      class RDP
        def self.rdp_client(env, rdp_info)
          config = nil
          opts   = {
            "full address:s"           => "#{rdp_info[:host]}:#{rdp_info[:port]}",
            "prompt for credentials:i" => "1",
            "username:s"               => rdp_info[:username],
          }

          # Create the ".rdp" file
          config_path = Pathname.new(Dir.tmpdir).join(
            "vagrant-rdp-#{Time.now.to_i}-#{rand(10000)}.rdp")
          config_path.open("w+") do |f|
            opts.each do |k, v|
              f.puts("#{k}:#{v}")
            end
          end

          # Build up the args to mstsc
          args = [config_path.to_s]
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
