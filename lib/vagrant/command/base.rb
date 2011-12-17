require 'log4r'

module Vagrant
  module Command
    # Base class for any CLI commands.
    #
    # This class provides documentation on the interface as well as helper
    # functions that a command has.
    class Base
      def initialize(argv, env)
        @argv = argv
        @env  = env
        @logger = Log4r::Logger.new("vagrant::command::#{self.class.to_s.downcase}")
      end

      # This is what is called on the class to actually execute it. Any
      # subclasses should implement this method and do any option parsing
      # and validation here.
      def execute; end

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
          puts opts.help
          return nil
        end

        opts.parse!(argv)
        return argv
      rescue OptionParser::InvalidOption
        puts opts.help
        return nil
      end

      # Yields a VM for each target VM for the command.
      #
      # This is a convenience method for easily implementing methods that
      # take a target VM (in the case of multi-VM) or every VM if no
      # specific VM name is specified.
      #
      # @param [String] name The name of the VM. Nil if every VM.
      def with_target_vms(name=nil)
        # First determine the proper array of VMs.
        vms = []
        if name
          raise Errors::MultiVMEnvironmentRequired if !@env.multivm?
          vms << @env.vms[name.to_sym]
          raise Errors::VMNotFoundError, :name => name if !vms[0]
        else
          vms = @env.vms_ordered
        end

        # Go through each VM and yield it!
        vms.each do |old_vm|
          # We get a new VM from the environment here to avoid potentially
          # stale VMs (if there was a config reload on the environment
          # or something).
          vm = @env.vms[old_vm.name]
          yield vm
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
