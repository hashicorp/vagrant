module Vagrant
  module Util
    class ZSHShell
      PREPEND = "# >>>> Vagrant zsh completion (start)".freeze
      STRING_INSERT = """fpath=(#{File.join(Vagrant.source_root, "contrib", "zsh")} $fpath)\ncompinit""".freeze
      APPEND = "# <<<<  Vagrant zsh completion (end)".freeze

      CONFIG_PATHS = [".zshrc"].freeze

      def self.shell_installed(home)
        CONFIG_PATHS.each do |path|
          config_file = File.join(home, path)
          if File.exists?(config_file)
            return config_file
          end
        end
        return nil
      end

      def self.is_installed(path)
        File.foreach(path) do |line|
          if line.include?(PREPEND)
            return true
          end
        end
        return false
      end

      def self.install(home)
        path = shell_installed(home)
        if path && !is_installed(path)
          File.open(path, "a") do |f|
            f.write("\n")
            f.write(PREPEND)
            f.write("\n")
            f.write(STRING_INSERT)
            f.write("\n")
            f.write(APPEND)
            f.write("\n")
          end
        end
      end
    end

    # Install autocomplete script for supported shells
    class InstallCLIAutocomplete
      SUPPORTED_SHELLS = {
        "zsh" => Vagrant::Util::ZSHShell
      }

      def self.install
        home = Dir.home
        SUPPORTED_SHELLS.each do |k, shell|
          shell.install(home)
        end
      end
    end
  end
end