require "pathname"
require "tmpdir"

require "vagrant/util/subprocess"

module VagrantPlugins
  module HostDarwin
    module Cap
      class RDP
        def self.rdp_client(env, rdp_info)
          config_path = self.generate_config_file(rdp_info)
          Vagrant::Util::Subprocess.execute("open", config_path.to_s)
        end

        protected

        # Generates an RDP connection file and returns the resulting path.
        # @return [String]
        def self.generate_config_file(rdp_info)
          opts   = {
            "drivestoredirect:s"       => "*",
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

            if rdp_info[:extra_args]
              rdp_info[:extra_args].each do |arg|
                f.puts("#{arg}")
              end
            end
          end

          return config_path
        end
      end
    end
  end
end
