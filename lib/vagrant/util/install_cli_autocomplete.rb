module Vagrant
  module Util
    # Generic installation of content to shell config file
    class InstallShellConfig

      PERPEND_STRING = "# >>>> Vagrant command completion (start)".freeze
      APPEND_STRING = "# <<<<  Vagrant command completion (end)".freeze

      attr_accessor :prepend_string
      attr_accessor :string_insert
      attr_accessor :append_string
      attr_accessor :config_paths

      def initialize(string_insert, config_paths)
        @prepend_string = PERPEND_STRING
        @string_insert = string_insert
        @append_string = APPEND_STRING
        @config_paths = config_paths
        @logger = Log4r::Logger.new("vagrant::util::install_shell_config")
      end

      # Searches a users home dir for a shell config file based on a
      # given home dir and a configured set of config paths. If there
      # are multiple config paths, it will return the first match.
      #
      # @param [string] path to users home dir
      # @return [string] path to shell config file if exists
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

      # Searches a given file for the existence of a set prepend string.
      # This can be used to find if vagrant has inserted some strings to a file
      #
      # @param [string] path to a file (config file)
      # @return [boolean] true if the prepend string is found in the file
      def is_installed(path)
        File.foreach(path) do |line|
          if line.include?(@prepend_string)
            @logger.info("Found completion already installed in #{path}")
            return true
          end
        end
        return false
      end

      # Given a path to the users home dir, will install some given strings
      # marked by a prepend and append string
      #
      # @param [string] path to users home dir
      # @return [string] path to shell config file that was modified if exists
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
      def initialize
        string_insert = """fpath=(#{File.join(Vagrant.source_root, "contrib", "zsh")} $fpath)\ncompinit""".freeze
        config_paths = [".zshrc".freeze].freeze
        super(string_insert, config_paths)
      end
    end

    # Install autocomplete script to bash config located as .bashrc or .bash_profile
    class InstallBashShellConfig < InstallShellConfig
      def initialize
        string_insert = ". #{File.join(Vagrant.source_root, 'contrib', 'bash', 'completion.sh')}".freeze
        config_paths = [".bashrc".freeze, ".bash_profile".freeze].freeze
        super(string_insert, config_paths)
      end
    end

    # Install autocomplete script for supported shells
    class InstallCLIAutocomplete
      SUPPORTED_SHELLS = {
        "zsh" => Vagrant::Util::InstallZSHShellConfig.new(),
        "bash" => Vagrant::Util::InstallBashShellConfig.new()
      }

      def self.install(shells=[])
        shells = SUPPORTED_SHELLS.keys() if shells.empty?
        home = Dir.home
        written_paths = []
        
        shells.map do |shell|
          if SUPPORTED_SHELLS[shell]
            written_paths.push(SUPPORTED_SHELLS[shell].install(home))
          else
            raise ArgumentError, "shell must be in #{SUPPORTED_SHELLS.keys()}"
          end
        end.compact
        return written_paths
      end
    end
  end
end
