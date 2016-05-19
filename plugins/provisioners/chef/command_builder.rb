module VagrantPlugins
  module Chef
    class CommandBuilder
      def self.command(type, config, options = {})
        new(type, config, options).command
      end

      attr_reader :type
      attr_reader :config
      attr_reader :options

      def initialize(type, config, options = {})
        @type    = type
        @config  = config
        @options = options.dup

        if type != :client && type != :solo
          raise "Unknown type `#{type.inspect}'!"
        end
      end

      def command
        if config.binary_env
          "#{config.binary_env} #{binary_path} #{args}"
        else
          "#{binary_path} #{args}"
        end
      end

      protected

      def binary_path
        binary_path = "chef-#{type}"

        if config.binary_path
          binary_path = File.join(config.binary_path, binary_path)
          if windows?
            binary_path = windows_friendly_path(binary_path)
          end
        end

        binary_path
      end

      def args
        args =  ""
        args << " --config #{provisioning_path("#{type}.rb")}"
        args << " --json-attributes #{provisioning_path("dna.json")}"
        args << " --local-mode" if options[:local_mode]
        args << " --legacy-mode" if options[:legacy_mode]
        args << " --log_level #{config.log_level}" if config.log_level
        args << " --no-color" if !options[:colored]

        if config.install && (config.version == :latest || config.version.to_s >= "11.0")
          args << " --force-formatter"
        end

        args << " #{config.arguments.strip}" if config.arguments

        args.strip
      end

      def provisioning_path(file)
        if windows?
          path = config.provisioning_path || "C:/vagrant-chef"
          return windows_friendly_path(File.join(path, file))
        else
          path = config.provisioning_path || "/tmp/vagrant-chef"
          return File.join(path, file)
        end
      end

      def windows_friendly_path(path)
        path = path.gsub("/", "\\")
        path = "c:#{path}" if path.start_with?("\\")
        return path
      end

      def windows?
        !!options[:windows]
      end
    end
  end
end
