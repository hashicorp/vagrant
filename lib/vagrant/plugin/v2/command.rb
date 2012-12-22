require 'log4r'

require "vagrant/util/safe_puts"

module Vagrant
  module Plugin
    module V2
      # This is the base class for a CLI command.
      class Command
        include Util::SafePuts

        def initialize(argv, env)
          @argv = argv
          @env  = env
          @logger = Log4r::Logger.new("vagrant::command::#{self.class.to_s.downcase}")
        end

        # This is what is called on the class to actually execute it. Any
        # subclasses should implement this method and do any option parsing
        # and validation here.
        def execute
        end

        protected

        # Parses the options given an OptionParser instance.
        #
        # This is a convenience method that properly handles duping the
        # originally argv array so that it is not destroyed.
        #
        # This method will also automatically detect "-h" and "--help"
        # and print help. And if any invalid options are detected, the help
        # will be printed, as well.
        #
        # If this method returns `nil`, then you should assume that help
        # was printed and parsing failed.
        def parse_options(opts=nil)
          # Creating a shallow copy of the arguments so the OptionParser
          # doesn't destroy the originals.
          argv = @argv.dup

          # Default opts to a blank optionparser if none is given
          opts ||= OptionParser.new

          # Add the help option, which must be on every command.
          opts.on_tail("-h", "--help", "Print this help") do
            safe_puts(opts.help)
            return nil
          end

          opts.parse!(argv)
          return argv
        rescue OptionParser::InvalidOption
          raise Errors::CLIInvalidOptions, :help => opts.help.chomp
        end

        # Yields a VM for each target VM for the command.
        #
        # This is a convenience method for easily implementing methods that
        # take a target VM (in the case of multi-VM) or every VM if no
        # specific VM name is specified.
        #
        # @param [String] name The name of the VM. Nil if every VM.
        # @param [Hash] options Additional tweakable settings.
        # @option options [Boolean] :single_target If true, then an
        #   exception will be raised if more than one target is found.
        def with_target_vms(names=nil, options=nil)
          # Using VMs requires a Vagrant environment to be properly setup
          raise Errors::NoEnvironmentError if !@env.root_path

          # Setup the options hash
          options ||= {}

          # Require that names be an array
          names ||= []
          names = [names] if !names.is_a?(Array)

          # The provider that we'll be loading up.
          provider = @env.default_provider

          # First determine the proper array of VMs.
          machines = []
          if names.length > 0
            names.each do |name|
              if pattern = name[/^\/(.+?)\/$/, 1]
                # This is a regular expression name, so we convert to a regular
                # expression and allow that sort of matching.
                regex = Regexp.new(pattern)

                @env.machine_names.each do |machine_name|
                  if machine_name =~ regex
                    machines << @env.machine(machine_name, provider)
                  end
                end

                raise Errors::VMNoMatchError if machines.empty?
              else
                # String name, just look for a specific VM
                machines << @env.machine(name.to_sym, provider)
                raise Errors::VMNotFoundError, :name => name if !machines[0]
              end
            end
          else
            # No name was given, so we return every VM in the order
            # configured.
            machines = @env.machine_names.map do |machine_name|
              @env.machine(machine_name, provider)
            end
          end

          # Make sure we're only working with one VM if single target
          if options[:single_target] && machines.length != 1
            primary = @env.primary_machine(provider)
            raise Errors::MultiVMTargetRequired if !primary
            machines = [primary]
          end

          # If we asked for reversed ordering, then reverse it
          machines.reverse! if options[:reverse]

          # Go through each VM and yield it!
          machines.each do |machine|
            yield machine
          end
        end

        # This method will split the argv given into three parts: the
        # flags to this command, the subcommand, and the flags to the
        # subcommand. For example:
        #
        #     -v status -h -v
        #
        # The above would yield 3 parts:
        #
        #     ["-v"]
        #     "status"
        #     ["-h", "-v"]
        #
        # These parts are useful because the first is a list of arguments
        # given to the current command, the second is a subcommand, and the
        # third are the commands given to the subcommand.
        #
        # @return [Array] The three parts.
        def split_main_and_subcommand(argv)
          # Initialize return variables
          main_args   = nil
          sub_command = nil
          sub_args    = []

          # We split the arguments into two: One set containing any
          # flags before a word, and then the rest. The rest are what
          # get actually sent on to the subcommand.
          argv.each_index do |i|
            if !argv[i].start_with?("-")
              # We found the beginning of the sub command. Split the
              # args up.
              main_args   = argv[0, i]
              sub_command = argv[i]
              sub_args    = argv[i + 1, argv.length - i + 1]

              # Break so we don't find the next non flag and shift our
              # main args.
              break
            end
          end

          # Handle the case that argv was empty or didn't contain any subcommand
          main_args = argv.dup if main_args.nil?

          return [main_args, sub_command, sub_args]
        end
      end
    end
  end
end
