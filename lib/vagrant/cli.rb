require 'log4r'
require 'optparse'

module Vagrant
  # Manages the command line interface to Vagrant.
  class CLI < Command::Base
    def initialize(argv, env)
      super

      @logger = Log4r::Logger.new("vagrant::cli")
      @main_args, @sub_command, @sub_args = split_main_and_subcommand(argv)

      @logger.info("CLI: #{@main_args.inspect} #{@sub_command.inspect} #{@sub_args.inspect}")
    end

    def execute
      if @main_args.include?("-v") || @main_args.include?("--version")
        # Version short-circuits the whole thing. Just print
        # the version and exit.
        @env.ui.info(I18n.t("vagrant.commands.version.output",
                            :version => Vagrant::VERSION),
                     :prefix => false)

        return 0
      elsif @main_args.include?("-h") || @main_args.include?("--help")
        # Help is next in short-circuiting everything. Print
        # the help and exit.
        help
        return 0
      end

      # If we reached this far then we must have a subcommand. If not,
      # then we also just print the help and exit.
      command_class = Vagrant.commands.get(@sub_command.to_sym) if @sub_command
      if !command_class || !@sub_command
        help
        return 0
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
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: vagrant [-v] [-h] command [<args>]"
        opts.separator ""
        opts.on("-v", "--version", "Print the version and exit.")
        opts.on("-h", "--help", "Print this help.")
        opts.separator ""
        opts.separator "Available subcommands:"

        # Add the available subcommands as separators in order to print them
        # out as well.
        keys = []
        Vagrant.commands.each { |key, value| keys << key.to_s }

        keys.sort.each do |key|
          opts.separator "     #{key}"
        end

        opts.separator ""
        opts.separator "For help on any individual command run `vagrant COMMAND -h`"
      end

      @env.ui.info(opts.help, :prefix => false)
    end
  end
end
