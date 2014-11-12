module VagrantPlugins
  module Chef
    module Omnibus
      OMNITRUCK = "https://www.getchef.com/chef/install.sh".freeze

      # Read more about the Omnibus installer here:
      # https://docs.getchef.com/install_omnibus.html
      def build_command(version, prerelease = false)
        command = "curl -sL #{OMNITRUCK} | sudo bash"

        if prerelease || version != :latest
          command << " -s --"
        end

        if prerelease
          command << " -p"
        end

        if version != :latest
          command << " -v \"#{version}\""
        end

        command
      end
      module_function :build_command
    end
  end
end
