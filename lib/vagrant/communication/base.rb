module Vagrant
  module Communication
    # The base class for any classes that provide an API for communicating
    # with the virtual machine.
    #
    # There are various stages that require Vagrant to copy files or
    # run commands on the target system, and communication classes provide
    # the abstraction necessary to perform these tasks, via SSH or some
    # other mechanism.
    #
    # Any subclasses of this class **must** implement all of the methods
    # below.
    class Base
      # Checks if the target machine is ready for communication.
      #
      # @return [Boolean]
      def ready?
      end

      # Download a file from the virtual machine to the local machine.
      #
      # @param [String] from Path of the file on the virtual machine.
      # @param [String] to Path to where to save the remote file.
      def download(from, to)
      end

      # Upload a file to the virtual machine.
      #
      # @param [String] from Path to a file to upload.
      # @param [String] to Path to where to save this file.
      def upload(from, to)
      end

      # Execute a command on the remote machine.
      #
      # @param [String] command Command to execute.
      # @yield [type, data] Realtime output of the command being executed.
      # @yieldparam [String] type Type of the output, `:stdout`, `:stderr`, etc.
      # @yieldparam [String] data Data for the given output.
      # @return [Integer] Exit code of the command.
      def execute(command, opts=nil)
      end

      # Execute a comand with super user privileges.
      #
      # See #execute for parameter information.
      def sudo(command, opts=nil)
      end

      # Executes a command and returns a boolean statement if it was successful
      # or not.
      #
      # This is implemented by default as expecting `execute` to return 0.
      def test(command, opts=nil)
        # Disable error checking no matter what
        opts = (opts || {}).merge(:error_check => false)

        # Successful if the exit status is 0
        execute(command, opts) == 0
      end
    end
  end
end
