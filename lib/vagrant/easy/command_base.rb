require "log4r"

module Vagrant
  module Easy
    # Base class for all easy commands. This contains the basic code
    # that knows how to run the easy commands.
    class CommandBase < Vagrant::Command::Base
      @@command = nil
      @@runner  = nil

      # This is called by the {EasyCommand.create} method when creating
      # an easy command to set the invocation command.
      def self.configure(name, &block)
        @@command = name
        @@runner  = block
      end

      def initialize(*args, &block)
        super

        @logger = Log4r::Logger.new("vagrant::easy_command::#{@@command}")
      end

      def execute
        # Build up a basic little option parser
        opts = OptionParser.new do |opts|
          opts.banner = "Usage: vagrant #{@@command}"
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        # Run the action for each VM.
        @logger.info("Running easy command: #{@@command}")
        with_target_vms(argv) do |vm|
          @logger.debug("Running easy command for VM: #{vm.name}")
          @@runner.call(Operations.new(vm))
        end

        # Exit status 0 every time for now
        0
      end
    end
  end
end
