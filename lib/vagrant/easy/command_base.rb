require "log4r"

module Vagrant
  module Easy
    # Base class for all easy commands. This contains the basic code
    # that knows how to run the easy commands.
    class CommandBase < Vagrant.plugin("1", :command)
      # This is the command that this easy command responds to
      attr_reader :command

      # This is called by the {EasyCommand.create} method when creating
      # an easy command to set the invocation command.
      def self.configure(name, &block)
        # We use class-level instance variables so that each class has
        # its own single command/runner. If we use class variables then this
        # whole base sharse a single one.
        @command = name
        @runner  = block
      end

      def initialize(*args, &block)
        if self.class == CommandBase
          raise "CommandBase must not be instantiated directly. Please subclass."
        end

        # Let the regular command state setup
        super

        # Get the command we're listening to and the block we're invoking
        # when we get that command, do some basic validation.
        @command = self.class.instance_variable_get(:@command)
        @runner  = self.class.instance_variable_get(:@runner)
        if !@command || !@runner
          raise ArgumentError, "CommandBase requires both a command and a runner"
        end

        @logger  = Log4r::Logger.new("vagrant::easy_command::#{@command}")
      end

      def execute
        # Build up a basic little option parser
        opts = OptionParser.new do |opts|
          opts.banner = "Usage: vagrant #{@command}"
        end

        # Parse the options
        argv = nil
        begin
          argv = parse_options(opts)
        rescue Errors::CLIInvalidOptions
          # This means that an invalid flag such as "--foo" was passed.
          # We usually show the help at this point (in built-in commands),
          # but since we don't know what our implementation does, we just
          # pass the flags through now.
          argv = @argv.dup
        end

        # If argv is nil then `parse_options` halted execution and we
        # halt our own execution here.
        return 0 if !argv

        # The Multi-VM argument is the first argument as long as the
        # first argument is not a flag.
        names = nil
        names = argv[0] if argv[0] !~ /^-/

        # Run the action for each VM.
        @logger.info("Running easy command: #{@command}")
        with_target_vms(names) do |vm|
          @logger.debug("Running easy command for VM: #{vm.name}")
          @runner.call(CommandAPI.new(vm, argv))
        end

        # Exit status 0 every time for now
        0
      end
    end
  end
end
