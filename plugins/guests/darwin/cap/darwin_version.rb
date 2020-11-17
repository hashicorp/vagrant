module VagrantPlugins
  module GuestDarwin
    module Cap
      class DarwinVersion
        
        VERSION_REGEX = /\d+.\d+.?\d*/.freeze

        # Get the darwin version
        #
        # @param [Machine]
        # @return [String] version of drawin
        def self.darwin_version(machine)
          output = ""
          machine.communicate.sudo("sysctl kern.osrelease") do |_, data|
            output = data
          end
          output.scan(VERSION_REGEX).first
        end

        # Get the darwin major version
        #
        # @param [Machine]
        # @return [int] major version of drawin (nil if version is not detected)
        def self.darwin_major_version(machine)
          output = ""
          machine.communicate.sudo("sysctl kern.osrelease") do |_, data|
            output = data
          end
          version_string = output.scan(VERSION_REGEX).first
          if version_string
            major_version = version_string.split(".").first.to_i
          else
            major_version = nil
          end
          major_version
        end
      end
    end
  end
end
