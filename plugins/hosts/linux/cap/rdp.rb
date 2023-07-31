# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "vagrant/util/which"

module VagrantPlugins
  module HostLinux
    module Cap
      class RDP
        def self.rdp_client(env, rdp_info)
          # Detect if an RDP client is available.
          # Prefer xfreerdp as it supports newer versions of RDP.
          rdp_client =
            if Vagrant::Util::Which.which("xfreerdp")
              "xfreerdp"
            elsif Vagrant::Util::Which.which("rdesktop")
              "rdesktop"
            else
              if Vagrant::Util::Platform.wsl?
                "mstsc.exe"
              else
                raise Vagrant::Errors::LinuxRDPClientNotFound
              end
            end

          args = []

          # Build appropriate arguments for the RDP client.
          case rdp_client
          when "xfreerdp"
            args << "/u:#{rdp_info[:username]}"
            args << "/p:#{rdp_info[:password]}" if rdp_info[:password]
            args << "/v:#{rdp_info[:host]}:#{rdp_info[:port]}"
            args += rdp_info[:extra_args] if rdp_info[:extra_args]
          when "rdesktop"
            args << "-u" << rdp_info[:username]
            args << "-p" << rdp_info[:password] if rdp_info[:password]
            args += rdp_info[:extra_args] if rdp_info[:extra_args]
            args << "#{rdp_info[:host]}:#{rdp_info[:port]}"
          when "mstsc.exe"
            # Setup password
            cmdKeyArgs = [
              "/add:#{rdp_info[:host]}:#{rdp_info[:port]}",
              "/user:#{rdp_info[:username]}",
              "/pass:#{rdp_info[:password]}",
            ]
            Vagrant::Util::Subprocess.execute("cmdkey.exe", *cmdKeyArgs)

            args = ["/v:#{rdp_info[:host]}:#{rdp_info[:port]}"]
            args += rdp_info[:extra_args] if rdp_info[:extra_args]
          end

          # Finally, run the client.
          Vagrant::Util::Subprocess.execute(rdp_client, *args, {:detach => true})
        end
      end
    end
  end
end
