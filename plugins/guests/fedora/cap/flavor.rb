module VagrantPlugins
  module GuestFedora
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
          if output =~ /(Fedora release 21).+/i
            return :f21
          else
            return :older
          end
	end
      end
    end
  end
end

