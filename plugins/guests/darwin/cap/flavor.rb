module VagrantPlugins
  module GuestDarwin
    module Cap
      class Flavor
        def self.flavor(machine)
          # Read the version file
          output = ""
          machine.communicate.sudo("sw_vers -productVersion", error_check: false) do |_, data|
            output = data
          end

          # Detect various flavors we care about
          if output =~ /10.15.\d+/
            return :catalina
          elsif output =~ /11.0.?\d*/
            return :big_sur
          else
            return :darwin
          end
        end
      end
    end
  end
end
