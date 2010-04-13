require 'optparse'

module Vagrant
  class Commands
    # This is the base command class which all sub-commands must
    # inherit from.
    class Base
      attr_reader :env

      def initialize(env)
        @env = env
      end

      # This method should be overriden by subclasses. This is the method
      # which is called by {Vagrant::Command} when a command is being
      # executed. The `args` parameter is an array of parameters to the
      # command (similar to ARGV)
      def execute(args)
        raise "Subcommands should implement the execute method properly."
      end

      # Parse options out of the command-line. This method uses `optparse`
      # to parse command line options. A block is required and will yield
      # the `OptionParser` object along with a hash which can be used to
      # store options and which will be returned as a result of the function.
      def parse_options(args)
        options = {}
        @parser = OptionParser.new do |opts|
          yield opts, options
        end

        @parser.parse!(args)
        options
      rescue OptionParser::InvalidOption
        show_help
      end

      # Prints the help for the given command. Prior to calling this method,
      # {#parse_options} must be called or a nilerror will be raised. This
      # is by design.
      def show_help
        puts @parser.help
        exit
      end
    end
  end
end