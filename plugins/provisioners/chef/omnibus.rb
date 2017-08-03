module VagrantPlugins
  module Chef
    # Read more about the Omnibus installer here:
    #
    #   https://docs.chef.io/install_omnibus.html
    #
    module Omnibus
      def sh_command(project, version, channel, omnibus_url, options = {})
        command =  "curl -sL #{omnibus_url}/install.sh | bash"
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

      def ps_command(project, version, channel, omnibus_url, options = {})
        command =  ". { iwr -useb #{omnibus_url}/install.ps1 } | iex; install"
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
