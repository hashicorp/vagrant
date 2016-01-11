module VagrantPlugins
  module Chef
    # Read more about the Omnibus installer here:
    #
    #   https://docs.chef.io/install_omnibus.html
    #
    module Omnibus
      OMNITRUCK = "https://omnitruck.chef.io".freeze

      def sh_command(project, version, channel, options = {})
        command =  "curl -sL #{OMNITRUCK}/install.sh | sudo bash"
        command << " -s -- -P \"#{project}\" -c \"#{channel}\""

        if version != :latest
          command << " -v \"#{version}\""
        end

        if options[:download_path]
          command << " -d \"#{options[:download_path]}\""
        end

        command
      end
      module_function :sh_command

      def ps_command(project, version, channel, options = {})
        command =  ". { iwr -useb #{OMNITRUCK}/install.ps1 } | iex; install"
        command << " -project '#{project}' -channel '#{channel}'"

        if version != :latest
          command << " -version '#{version}'"
        end

        command
      end
      module_function :ps_command
    end
  end
end
