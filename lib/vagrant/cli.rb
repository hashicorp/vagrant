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
      command_class = nil
      if @sub_command
        command_class = Vagrant.plugin("2").manager.commands[@sub_command.to_sym]
      end

      if !command_class || !@sub_command
        help
        return 1
      end
      @logger.debug("Invoking command class: #{command_class} #{@sub_args.inspect}")

      # Initialize and execute the command class, returning the exit status.
      result = command_class.new(@sub_args, @env).execute
      result = 0 if !result.is_a?(Fixnum)
      return result
    end

    # This prints out the help for the CLI.
    def help
      # We use the optionparser for this. Its just easier. We don't use
      # an optionparser above because I don't think the performance hits
      # of creating a whole object are worth checking only a couple flags.
      opts = OptionParser.new do |o|
        o.banner = "Usage: vagrant [-v] [-h] command [<args>]"
        o.separator ""
        o.on("-v", "--version", "Print the version and exit.")
        o.on("-h", "--help", "Print this help.")
        o.separator ""
        o.separator "Available subcommands:"

        # Add the available subcommands as separators in order to print them
        # out as well.
        keys = []
        Vagrant.plugin("2").manager.commands.each do |key, _|
          keys << key
        end

        keys.sort.each do |key|
          o.separator "     #{key}"
        end

        o.separator ""
        o.separator "For help on any individual command run `vagrant COMMAND -h`"
      end

      @env.ui.info(opts.help, :prefix => false)
    end
  end
end
