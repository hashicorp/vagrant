require 'log4r'
require 'optparse'

module Vagrant
  # Manages the command line interface to Vagrant.
  class CLI < Vagrant.plugin("2", :command)
    def initialize(argv, env)
      super

      @logger = Log4r::Logger.new("vagrant::cli")
      @main_args, @sub_command, @sub_args = split_main_and_subcommand(argv)

      @logger.info("CLI: #{@main_args.inspect} #{@sub_command.inspect} #{@sub_args.inspect}")
    end

    def execute
      if @main_args.include?("-h") || @main_args.include?("--help")
        # Help is next in short-circuiting everything. Print
        # the help and exit.
        help
        return 0
      end

      # If we reached this far then we must have a subcommand. If not,
      # then we also just print the help and exit.
      command_plugin = nil
      if @sub_command
        command_plugin = Vagrant.plugin("2").manager.commands[@sub_command.to_sym]
      end

      if !command_plugin || !@sub_command
        help
        return 1
      end

      command_class = command_plugin[0].call
      @logger.debug("Invoking command class: #{command_class} #{@sub_args.inspect}")

      # Initialize and execute the command class, returning the exit status.
      result = 0
      begin
        result = command_class.new(@sub_args, @env).execute
      rescue Interrupt
        @env.ui.info(I18n.t("vagrant.cli_interrupt"))
        result = 1
      end

      result = 0 if !result.is_a?(Fixnum)
      return result
    end

    # This prints out the help for the CLI.
    def help
      # We use the optionparser for this. Its just easier. We don't use
      # an optionparser above because I don't think the performance hits
      # of creating a whole object are worth checking only a couple flags.
      opts = OptionParser.new do |o|
        o.banner = "Usage: vagrant [options] <command> [<args>]"
        o.separator ""
        o.on("-v", "--version", "Print the version and exit.")
        o.on("-h", "--help", "Print this help.")
        o.separator ""
        o.separator "Common commands:"

        # Add the available subcommands as separators in order to print them
        # out as well.
        commands = {}
        longest = 0
        Vagrant.plugin("2").manager.commands.each do |key, data|
          # Skip non-primary commands. These only show up in extended
          # help output.
          next if !data[1][:primary]

          key           = key.to_s
          klass         = data[0].call
          commands[key] = klass.synopsis
          longest       = key.length if key.length > longest
        end

        commands.keys.sort.each do |key|
          o.separator "     #{key.ljust(longest+2)} #{commands[key]}"
          @env.ui.machine("cli-command", key.dup)
        end

        o.separator ""
        o.separator "For help on any individual command run `vagrant COMMAND -h`"
        o.separator ""
        o.separator "Additional subcommands are available, but are either more advanced"
        o.separator "or not commonly used. To see all subcommands, run the command"
        o.separator "`vagrant list-commands`."
      end

      @env.ui.info(opts.help, prefix: false)
    end
  end
end
