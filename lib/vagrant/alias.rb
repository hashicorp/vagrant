require "vagrant/registry"

module Vagrant
  # This class imports and processes CLI aliases stored in ~/.vagrant.d/aliases
  class Alias
    def initialize(env)
      @aliases = Registry.new
      @env = env

      if env.aliases_path.file?
        env.aliases_path.readlines.each do |line|
          # separate keyword-command pairs
          keyword, command = interpret(line)

          if keyword && command
            register(keyword, command)
          end
        end
      end
    end

    # This returns all the registered alias commands.
    def commands
      @aliases
    end

    # This interprets a raw line from the aliases file.
    def interpret(line)
      # is it a comment?
      return nil if line.strip.start_with?("#")

      keyword, command = line.split("=", 2).collect(&:strip)

      # validate the keyword
      if keyword.match(/\s/i)
        raise Errors::AliasInvalidError, alias: line, message: "Alias keywords must not contain any whitespace."
      end

      [keyword, command]
    end

    # This registers an alias.
    def register(keyword, command)
      @aliases.register(keyword.to_sym) do
        lambda do |args|
          # directly execute shell commands
          if command.start_with?("!")
            return Util::SafeExec.exec "#{command[1..-1]} #{args.join(" ")}".strip
          end

          return CLI.new(command.split.concat(args), @env).execute
        end
      end
    end
  end
end
