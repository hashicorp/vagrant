module VagrantPlugins
  module GuestCentos
    module Cap
      class Flavor
        def self.flavor(machine)
          # Read the version file
          output = ""
          machine.communicate.sudo("cat /etc/centos-release") do |_, data|
            output = data
          end

          # Detect various flavors we care about
          if output =~ /(CentOS)( .+)? 7/i
            return :centos_7
          elsif output =~ /(CentOS)( .+)? 8/i
            return :centos_8
          else
            return :centos
          end
        end
      end
    end
  end
end
