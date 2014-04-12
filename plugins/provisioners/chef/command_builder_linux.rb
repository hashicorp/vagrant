module VagrantPlugins
  module Chef
    class CommandBuilderLinux < CommandBuilder
      def build_command
        if @client_type == :solo
          return build_command_solo
        else
          return build_command_client
        end
      end

      protected

      def build_command_client
        command_env  = @config.binary_env ? "#{@config.binary_env} " : ""
        command_args = @config.arguments ? " #{@config.arguments}" : ""

        binary_path = "chef-client"
        binary_path ||= File.join(@config.binary_path, binary_path)

        return "#{command_env}#{binary_path} " +
          "-c #{@config.provisioning_path}/client.rb " +
          "-j #{@config.provisioning_path}/dna.json #{command_args}"
      end

      def build_command_solo
        options = [
          "-c #{@config.provisioning_path}/solo.rb",
          "-j #{@config.provisioning_path}/dna.json"
        ]

        if !@machine.env.ui.is_a?(Vagrant::UI::Colored)
          options << "--no-color"
        end

        command_env = @config.binary_env ? "#{@config.binary_env} " : ""
        command_args = @config.arguments ? " #{@config.arguments}" : ""

        binary_path = "chef-solo"
        binary_path ||= File.join(@config.binary_path, binary_path)

        return "#{command_env}#{binary_path} " +
          "#{options.join(" ")} #{command_args}"
      end
    end
  end
end
