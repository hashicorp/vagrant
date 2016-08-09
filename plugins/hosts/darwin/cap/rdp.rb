require "pathname"
require "tmpdir"

require "vagrant/util/subprocess"

module VagrantPlugins
  module HostDarwin
    module Cap
      class RDP
        def self.rdp_client(env, rdp_info)
          config_path = self.generate_config_file(rdp_info)
          begin
            Vagrant::Util::Subprocess.execute("open", config_path.to_s)
          ensure
            # Note: this technically will never get run; neither would an
            # at_exit call. The reason is that `exec` replaces this process,
            # effectively the same as `kill -9`. This is solely here to prove
            # that and so that future developers do not waste a ton of time
            # try to identify why Vagrant is leaking RDP connection files.
            # There is a catch-22 here in that we can't delete the file before
            # we exec, and we can't delete the file after we exec :(.
            File.unlink(config_path) if File.file?(config_path)
          end
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
          t = ::Tempfile.new(["vagrant-rdp", ".rdp"]).tap do |f|
            f.binmode

            opts.each do |k, v|
              f.puts("#{k}:#{v}")
            end

            if rdp_info[:extra_args]
              rdp_info[:extra_args].each do |arg|
                f.puts("#{arg}")
              end
            end

            f.fsync
            f.close
          end

          return t.path
        end
      end
    end
  end
end
