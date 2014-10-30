module VagrantPlugins
  module GuestFedora
    module Cap
      class Flavor
        def self.flavor(machine)
          @logger = Log4r::Logger.new("vagrant::guest::fedora::cap::flavor")
          # Establish the simple fedora symbol
          #:fedora

          # Read the version file
          output = ""
          machine.communicate.sudo("grep VERSION_ID /etc/os-release") do |type, data|
            output += data if type == :stdout
          end
          version = output.split("=")[1].chomp!.to_i

          @logger.debug("output= #{output}; version = #{version}")
          # Detect various flavors we care about
          if version >= 20
            @logger.debug("Fedora flavor identified as fedora_#{output}")
            return :"fedora_#{version}"
          else if version >= 20
            @logger.debug("Fedora flavor identified as fedora_#{output}")
            return :"fedora_#{version}"
	  else
            @logger.debug("Fedora flavor identified as fedora")
            return :fedora
          end
        end
      end
    end
  end
end
