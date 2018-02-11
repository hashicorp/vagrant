require "vagrant/registry"

module Vagrant
  # This class imports and processes CLI aliases stored in ~/.vagrant.d/aliases
  class Alias
    def initialize(env)
      @aliases = Registry.new

      aliases_file = env.home_path.join("aliases")
      if aliases_file.file?
        aliases_file.readlines.each do |line|
          # skip comments
          next if line.strip.start_with?("#")

          # separate keyword-command pairs
          keyword, command = line.split("=").collect(&:strip)

          @aliases.register(keyword.to_sym) do
            lambda do |args|
              # directly execute shell commands
              if command.start_with?("!")
                return exec "#{command[1..-1]} #{args.join(" ")}".strip
              end

              return CLI.new(command.split.concat(args), env).execute
            end
          end
        end
      end
    end

    def commands
      @aliases
    end
  end
end
