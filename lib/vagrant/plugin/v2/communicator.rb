require "timeout"

module Vagrant
  module Plugin
    module V2
      # Base class for a communicator in Vagrant. A communicator is
      # responsible for communicating with a machine in some way. There
      # are various stages of Vagrant that require things such as uploading
      # files to the machine, executing shell commands, etc. Implementors
      # of this class are expected to provide this functionality in some
      # way.
      #
      # Note that a communicator must provide **all** of the methods
      # in this base class. There is currently no way for one communicator
      # to provide say a more efficient way of uploading a file, but not
      # provide shell execution. This sort of thing will come in a future
      # version.
      class Communicator
        # This returns true/false depending on if the given machine
        # can be communicated with using this communicator. If this returns
        # `true`, then this class will be used as the primary communication
        # method for the machine.
        #
        # @return [Boolean]
        def self.match?(machine)
          true
        end

        # Initializes the communicator with the machine that we will be
        # communicating with. This base method does nothing (it doesn't
        # even store the machine in an instance variable for you), so you're
        # expected to override this and do something with the machine if
        # you care about it.
        #
        # @param [Machine] machine The machine this instance is expected to
        #   communicate with.
        def initialize(machine)
        end

        # Checks if the target machine is ready for communication. If this
        # returns true, then all the other methods for communicating with
        # the machine are expected to be functional.
        #
        # @return [Boolean]
        def ready?
          false
        end

        # wait_for_ready waits until the communicator is ready, blocking
        # until then. It will wait up to the given duration or raise an
        # exception if something goes wrong.
        #
        # @param [Fixnum] duration Timeout in seconds.
        # @return [Boolean] Will return true on successful connection
        #   or false on timeout.
        def wait_for_ready(duration)
          # By default, we implement a naive solution.
          begin
            Timeout.timeout(duration) do
              while true
                return true if ready?
                sleep 0.5
              end
            end
          rescue Timeout::Error
            # We timed out, we failed.
          end

          return false
        end

        # Download a file from the remote machine to the local machine.
        #
        # @param [String] from Path of the file on the remote machine.
        # @param [String] to Path of where to save the file locally.
        def download(from, to)
        end

        # Upload a file to the remote machine.
        #
        # @param [String] from Path of the file locally to upload.
        # @param [String] to Path of where to save the file on the remote
        #   machine.
        def upload(from, to)
        end

        # Execute a command on the remote machine. The exact semantics
        # of this method are up to the implementor, but in general the
        # users of this class will expect this to be a shell.
        #
        # This method gives you no way to write data back to the remote
        # machine, so only execute commands that don't expect input.
        #
        # @param [String] command Command to execute.
        # @yield [type, data] Realtime output of the command being executed.
        # @yieldparam [String] type Type of the output. This can be
        #   `:stdout`, `:stderr`, etc. The exact types are up to the
        #   implementor.
        # @yieldparam [String] data Data for the given output.
        # @return [Integer] Exit code of the command.
        def execute(command, opts=nil)
        end

        # Executes a command on the remote machine with administrative
        # privileges. See {#execute} for documentation, as the API is the
        # same.
        #
        # @see #execute
        def sudo(command, opts=nil)
        end

        # Executes a command and returns true if the command succeeded,
        # and false otherwise. By default, this executes as a normal user,
        # and it is up to the communicator implementation if they expose an
        # option for running tests as an administrator.
        #
        # @see #execute
        def test(command, opts=nil)
        end
      end
    end
  end
end
