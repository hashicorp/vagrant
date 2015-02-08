module VagrantPlugins
  module GuestRedHat
    module Cap
      class Flavor
        def self.flavor(machine)
          # Read the version file
          output = ""
          machine.communicate.sudo("cat /etc/redhat-release") do |type, data|
            output += data if type == :stdout
          end
          output.chomp!

          # Detect various flavors we care about
          if output =~ /(CentOS|Red Hat Enterprise|Scientific) Linux( .+)? release 7/i
            return :rhel_7
          else
            return :rhel
          end
        end
      end
    end
  end
end
