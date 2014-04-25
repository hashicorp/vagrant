module VagrantPlugins
  module Chef
    class CommandBuilderWindows < CommandBuilder
      def build_command
        "#{chef_binary_path} #{chef_arguments}"
      end

      protected

      def chef_binary_path
        binary_path = "chef-#{@client_type}"
        binary_path = win_path(File.join(@config.binary_path, binary_path)) if @config.binary_path
        binary_path
      end

      def chef_arguments
        chef_arguments = "-c #{provisioning_path("#{@client_type}.rb")}"
        chef_arguments << " -j #{provisioning_path("dna.json")}"
        chef_arguments << " #{@config.arguments}" if @config.arguments
        chef_arguments.strip
      end

      def provisioning_path(file)
        win_path(File.join(@config.provisioning_path, file))
      end

      def win_path(path)
        path.gsub!("/", "\\")
        "c:#{path}" if path.start_with?("\\")
      end
    end
  end
end
