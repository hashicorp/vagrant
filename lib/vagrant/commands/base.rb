require 'optparse'

module Vagrant
  class Commands
    # This is the base command class which all sub-commands must
    # inherit from.
    class Base
      attr_reader :env

      class <<self
        # Contains the list of registered subcommands. The registered commands are
        # stored in a hash table and are therefore unordered.
        #
        # @return [Hash]
        def subcommands
          @subcommands ||= {}
        end

        # Registers a command with `vagrant`. This method allows 3rd parties to
        # dynamically add new commands to the `vagrant` command, allowing plugins
        # to act as 1st class citizens within vagrant.
        #
        # @param [String] key The subcommand which will invoke the registered command.
        # @param [Class] klass. The subcommand class (a subclass of {Base})
        def subcommand(key, klass)
          subcommands[key] = klass
        end

        # Dispatches a subcommand to the proper registered command. Otherwise, it
        # prints a help message.
        def dispatch(env, name, *args)
          klass = subcommands[name]
          if klass.nil?
            puts_help
            return # For tests
          end

          command = klass.new(env)
          command.execute(args)
        end

        # Prints out the list of supported commands and their descriptions (if
        # available) then exits.
        def puts_help
          puts "Usage: vagrant SUBCOMMAND ...\n\n"

          puts "Supported commands:"
          subcommands.each do |key, klass|
            puts "#{' ' * 4}#{key.ljust(20)}#{klass.description}"
          end

          exit
        end

        # Sets or reads the description, depending on if the value is set in the
        # parameter.
        def description(value=nil)
          @description ||= ''

          return @description if value.nil?
          @description = value
        end
      end

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