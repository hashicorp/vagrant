module VagrantPlugins
  module GuestLinux
    module Cap
      class ReadIPAddress
        def self.read_ip_address(machine)
          command = "ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1 }'"
          result  = ""
          machine.communicate.execute(command) do |type, data|
            result << data if type == :stdout
          end

          result.chomp.split("\n").first
        end
      end
    end
  end
end
