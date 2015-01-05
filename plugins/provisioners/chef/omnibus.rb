module VagrantPlugins
  module Chef
    module Omnibus
      OMNITRUCK = "https://www.chef.io/chef/install.sh".freeze

      # Read more about the Omnibus installer here:
      # https://docs.getchef.com/install_omnibus.html
      def build_command(version, prerelease = false, download_path = nil)
        command = "curl -sL #{OMNITRUCK} | sudo bash"

        if prerelease || version != :latest || download_path != nil
          command << " -s --"
        end

        if prerelease
          command << " -p"
        end

        if version != :latest
          command << " -v \"#{version}\""
        end

        if download_path
          command << " -d \"#{download_path}\""
        end

        command
      end
      module_function :build_command
    end
  end
end
