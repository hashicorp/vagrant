require "optparse"

module VagrantPlugins
  module CommandListCommands
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "outputs all available Vagrant subcommands, even non-primary ones"
      end

      def execute
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant list-commands"
        end

        argv = parse_options(opts)
        return if !argv

        # Add the available subcommands as separators in order to print them
        # out as well.
        commands = {}
        longest = 0
        Vagrant.plugin("2").manager.commands.each do |key, data|
          key           = key.to_s
          klass         = data[0].call
          commands[key] = klass.synopsis
          longest       = key.length if key.length > longest
        end

        command_output = []
        commands.keys.sort.each do |key|
          command_output << "#{key.ljust(longest+2)} #{commands[key]}"
          @env.ui.machine("cli-command", key.dup)
        end

        @env.ui.info(
          I18n.t("vagrant.list_commands", list: command_output.join("\n")))

        # Success, exit status 0
        0
      end
    end
  end
end
