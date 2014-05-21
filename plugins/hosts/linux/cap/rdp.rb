require "vagrant/util/which"

module VagrantPlugins
  module HostLinux
    module Cap
      class RDP
        def self.rdp_client(env, rdp_info)
          if !Vagrant::Util::Which.which("rdesktop")
            raise Vagrant::Errors::LinuxRDesktopNotFound
          end

          args = []
          args << "-u" << rdp_info[:username]
          args << "-p" << rdp_info[:password] if rdp_info[:password]
          args += rdp_info[:extra_args] if rdp_info[:extra_args]
          args << "#{rdp_info[:host]}:#{rdp_info[:port]}"

          Vagrant::Util::Subprocess.execute("rdesktop", *args)
        end
      end
    end
  end
end
