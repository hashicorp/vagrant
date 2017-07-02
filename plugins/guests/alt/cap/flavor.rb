module VagrantPlugins
  module GuestALT
    module Cap
      class Flavor
        def self.flavor(machine)
          # Read the version file
          if !comm.test("test -f /etc/os-release")
            version = nil
            machine.communicate.sudo("grep VERSION_ID /etc/os-release") do |type, data|
              if type == :stdout
                version = data.split("=")[1].chomp.to_i
              end
            end

            if version.nil?
              return :alt
            else
              return :"alt_#{version}"
            end
          else
            output = ""
            machine.communicate.sudo("cat /etc/altlinux-release") do |_, data|
              output = data
            end

            # Detect various flavors we care about
            if output =~ /(ALT Workstation K|ALT Linux starter kit)\s*8( .+)?/i
              return :alt_8
            else
              return :alt
            end
          end
        end
      end
    end
  end
end
