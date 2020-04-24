module Vagrant
  module Util
    # Generic installation of content to shell config file
    class InstallShellConfig
      
      attr_accessor :prepend_string
      attr_accessor :string_insert
      attr_accessor :append_string
      attr_accessor :config_paths

      def initialize(prepend_string, string_insert, append_string, config_paths)
        @prepend_string = prepend_string
        @string_insert = string_insert
        @append_string = append_string
        @config_paths = config_paths
        @logger = Log4r::Logger.new("vagrant::util::install_shell_config")
      end

      def shell_installed(home)
        @logger.info("Searching for config in home #{home}")
        @config_paths.each do |path|
          config_file = File.join(home, path)
          if File.exists?(config_file)
            @logger.info("Found config file #{config_file}")
            return config_file
          end
        end
        return nil
      end

      def is_installed(path)
        File.foreach(path) do |line|
          if line.include?(@prepend_string)
            @logger.info("Found completion already installed in #{path}")
            return true
          end
        end
        return false
      end

      def install(home)
        path = shell_installed(home)
        if path && !is_installed(path)
          File.open(path, "a") do |f|
            f.write("\n")
            f.write(@prepend_string)
            f.write("\n")
            f.write(@string_insert)
            f.write("\n")
            f.write(@append_string)
            f.write("\n")
          end
        end
        return path
      end
    end

    # Install autocomplete script to zsh config located as .zshrc
    class InstallZSHShellConfig < InstallShellConfig
      def initialize()
        prepend_string = "# >>>> Vagrant zsh completion (start)".freeze
        string_insert = """fpath=(#{File.join(Vagrant.source_root, "contrib", "zsh")} $fpath)\ncompinit""".freeze
        append_string = "# <<<<  Vagrant zsh completion (end)".freeze
        config_paths = [".zshrc".freeze].freeze
        super(prepend_string, string_insert, append_string, config_paths)
      end
    end

    # Install autocomplete script to bash config located as .bashrc or .bash_profile
    class InstallBashShellConfig < InstallShellConfig
      def initialize()
        prepend_string = "# >>>> Vagrant bash completion (start)".freeze
        string_insert = ". #{File.join(Vagrant.source_root, 'contrib', 'bash', 'completion.sh')}".freeze
        append_string = "# <<<<  Vagrant bash completion (end)".freeze
        config_paths = [".bashrc".freeze, ".bash_profile".freeze].freeze
        super(prepend_string, string_insert, append_string, config_paths)
      end
    end

    # Install autocomplete script for supported shells
    class InstallCLIAutocomplete
      SUPPORTED_SHELLS = {
        "zsh" => Vagrant::Util::InstallZSHShellConfig.new(),
        "bash" => Vagrant::Util::InstallBashShellConfig.new()
      }

      def self.install
        home = Dir.home
        written_paths = []
        SUPPORTED_SHELLS.each do |k, shell|
          p = shell.install(home)
          if p
            written_paths.push(p)
          end
        end
        return written_paths
      end
    end
  end
end
