module VagrantPlugins
  module Chef
    class CommandBuilder
      def initialize(config, client_type, is_windows = false, is_ui_colored = false)
        @client_type   = client_type
        @config        = config
        @is_windows    = is_windows
        @is_ui_colored = is_ui_colored

        if client_type != :solo && client_type != :client
          raise 'Invalid client_type, expected solo or client'
        end
      end

      def build_command
        "#{command_env}#{chef_binary_path} #{chef_arguments}"
      end

      protected

      def command_env
        @config.binary_env ? "#{@config.binary_env} " : ""
      end

      def chef_binary_path
        binary_path = "chef-#{@client_type}"
        if @config.binary_path
          binary_path = File.join(@config.binary_path, binary_path)
          if windows?
            binary_path = windows_friendly_path(binary_path)
          end
        end
        binary_path
      end

      def chef_arguments
        chef_arguments = "-c #{provisioning_path("#{@client_type}.rb")}"
        chef_arguments << " -j #{provisioning_path("dna.json")}"
        chef_arguments << " #{@config.arguments}" if @config.arguments
        chef_arguments << " --no-color" unless color?
        chef_arguments.strip
      end

      def provisioning_path(file)
        if windows?
          path = @config.provisioning_path || "C:/vagrant-chef"
          return windows_friendly_path(File.join(path, file))
        else
          path = @config.provisioning_path || "/tmp/vagrant-chef"
          return File.join(path, file)
        end
      end

      def windows_friendly_path(path)
        path = path.gsub("/", "\\")
        path = "c:#{path}" if path.start_with?("\\")
        return path
      end

      def windows?
        !!@is_windows
      end

      def color?
        !!@is_ui_colored
      end
    end
  end
end
