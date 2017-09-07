module VagrantPlugins
  module GuestALT
    module Cap
      class Flavor
        def self.flavor(machine)
          comm = machine.communicate

          # Read the version file
          if comm.test("test -f /etc/os-release")
            name = nil
            comm.sudo("grep NAME /etc/os-release") do |type, data|
              if type == :stdout
                name = data.split("=")[1].gsub!(/\A"|"\Z/, '')
              end
            end

            if !name.nil? and name == "Sisyphus"
              return :alt
            end

            version = nil
            comm.sudo("grep VERSION_ID /etc/os-release") do |type, data|
              if type == :stdout
                verstr = data.split("=")[1]
                if verstr == "p8"
                  version = 8
                elsif verstr =~ /^[[\d]]/
                  version = verstr.chomp.to_i
                  subversion = verstr.chomp.split(".")[1].to_i
                  if subversion > 90
                    version += 1
                  end
                end
              end
            end

            if version.nil? or version == 0
              return :alt
            else
              return :"alt_#{version}"
            end
          else
            output = ""
            comm.sudo("cat /etc/altlinux-release") do |_, data|
              output = data
            end

            # Detect various flavors we care about
            if output =~ /(ALT SP|ALT Education|ALT Workstation|ALT Workstation K|ALT Linux starter kit)\s*8(\.[1-9])?( .+)?/i
              return :alt_8
            elsif output =~ /ALT\s+8(\.[1-9])?( .+)?\s.+/i
              return :alt_8
            elsif output =~ /ALT Linux p8( .+)?/i
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
