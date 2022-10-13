module VagrantPlugins
  module GuestRedHat
    module Cap
      class Flavor
        def self.flavor(machine)
          # Read the version file
          output = ""
          machine.communicate.sudo("cat /etc/redhat-release") do |_, data|
            output = data
          end

          # Detect various flavors we care about
          if output =~ /(Red Hat Enterprise|Scientific|Cloud|Virtuozzo)\s*Linux( .+)? release 7/i
            return :rhel_7
          elsif output =~ /(Red Hat Enterprise|Scientific|Cloud|Virtuozzo)\s*Linux( .+)? release 8/i
            return :rhel_8
          else
            return :rhel
          end
        end
      end
    end
  end
end
