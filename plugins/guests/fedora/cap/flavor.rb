module VagrantPlugins
  module GuestFedora
    module Cap
      class Flavor
        def self.flavor(machine)
          # Read the version file
          version = nil
          machine.communicate.sudo("grep VERSION_ID /etc/os-release") do |type, data|
            if type == :stdout
              version = data.split("=")[1].chomp.to_i
            end
          end

          if version.nil?
            return :fedora
          else
            return :"fedora_#{version}"
          end
        end
      end
    end
  end
end
