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

      class << self
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
          show_help
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

      # Parses the options for a given command and if a name was
      # given, it calls the single method, otherwise it calls the all
      # method. This helper is an abstraction which allows commands to
      # easily be used in both regular and multi-VM environments.
      def all_or_single(args, method_prefix)
        args = parse_options(args)

        single_method = "#{method_prefix}_single".to_sym
        if args[0]
          send(single_method, args[0])
        else
          env.vms.keys.each do |name|
            send(single_method, name)
          end
        end
      end

      # Shows the version
      def puts_version
        puts VERSION
      end

      # Returns the `OptionParser` instance to be used with this subcommand,
      # based on the specs defined in {#options_spec}.
      def option_parser(reload=false)
        @option_parser = nil if reload
        @option_parser ||= OptionParser.new do |opts|
          # The --help flag is available on all children commands, and will
          # immediately show help.
          opts.on("--help", "Show help for the current subcommand.") do
            show_help
          end

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

        my_klass = self.class
        if !my_klass.subcommands.empty?
          puts "\nSupported subcommands:"
          my_klass.subcommands.keys.sort.each do |key|
            klass = my_klass.subcommands[key]
            next if klass.description.empty?

            puts "#{' ' * 8}#{key.ljust(20)}#{klass.description}"
          end

          puts "\nFor help on a specific subcommand, run `vagrant SUBCOMMAND --help`"
        end

        exit
      end
    end
  end
end
