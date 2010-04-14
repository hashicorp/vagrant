require 'optparse'

module Vagrant
  class Commands
    # This is the base command class which all sub-commands must
    # inherit from. Subclasses of bases are expected to implement two
    # methods: {#execute} and {#options_spec} (optional). The former
    # defines the actual behavior of the command while the latter is a spec
    # outlining the options that the command may take.
    class Base
      include Util

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
        def dispatch(env, *args)
          klass = subcommands[args[0]] unless args.empty?
          if klass.nil?
            # Run _this_ command!
            command = self.new(env)
            command.execute(args)
            return
          end

          # Shift off the front arg, since we just consumed it in finding the
          # subcommand.
          args.shift

          # Dispatch to the next class
          klass.dispatch(env, *args)
        end

        # Prints out the list of supported commands and their descriptions (if
        # available) then exits.
        def puts_help
          puts "Usage: vagrant SUBCOMMAND ...\n\n"

          puts "Supported commands:"
          subcommands.keys.sort.each do |key|
            klass = subcommands[key]
            next if klass.description.empty?

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
        parse_options(args)

        if options[:version]
          puts_version
        else
          # Just print out the help, since this top-level command does nothing
          # on its own
          self.class.puts_help
        end
      end

      # This method is called by the base class to get the `optparse` configuration
      # for the command.
      def options_spec(opts)
        opts.banner = "Usage: vagrant SUBCOMMAND"

        opts.on("--version", "Output running Vagrant version.") do |v|
          options[:version] = v
        end
      end

      #-------------------------------------------------------------------
      # Methods below are not meant to be overriden/implemented by subclasses
      #-------------------------------------------------------------------

      # Shows the version
      def puts_version
        File.open(File.join(PROJECT_ROOT, "VERSION"), "r") do |f|
          puts f.read
        end
      end

      # Returns the `OptionParser` instance to be used with this subcommand,
      # based on the specs defined in {#options_spec}.
      def option_parser(reload=false)
        @option_parser = nil if reload
        @option_parser ||= OptionParser.new do |opts|
          options_spec(opts)
        end
      end

      # The options for the given command. This will just be an empty hash
      # until {#parse_options} is called.
      def options
        @options ||= {}
      end

      # Parse options out of the command-line. This method uses `optparse`
      # to parse command line options.
      def parse_options(args)
        option_parser.parse!(args)
        options
      rescue OptionParser::InvalidOption
        show_help
      end

      # Gets the description of the command. This is similar grabbed from the
      # class level.
      def description
        self.class.description
      end

      # Prints the help for the given command. Prior to calling this method,
      # {#parse_options} must be called or a nilerror will be raised. This
      # is by design.
      def show_help
        if !description.empty?
          puts "Description: #{description}"
        end

        puts option_parser.help
        exit
      end
    end
  end
end