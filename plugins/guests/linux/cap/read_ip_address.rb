module VagrantPlugins
  module GuestLinux
    module Cap
      class ReadIPAddress
        def self.read_ip_address(machine)

          comm = machine.communicate

          if comm.test("which ip")
            command = "LANG=en ip addr  | grep -Po 'inet \\K[\\d.]+' | grep -v 127.0.0.1"
          else
            command = "LANG=en ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1 }'"
          end

          result  = ""
          comm.sudo(command) do |type, data|
            result << data if type == :stdout
          end

          result.chomp.split("\n").first
        end
      end
    end
  end
end
