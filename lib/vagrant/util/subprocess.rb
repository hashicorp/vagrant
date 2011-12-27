require 'childprocess'
require 'log4r'

module Vagrant
  module Util
    # Execute a command in a subprocess, gathering the results and
    # exit status.
    #
    # This class also allows you to read the data as it is outputted
    # from the subprocess in real time, by simply passing a block to
    # the execute method.
    class Subprocess
      # Convenience method for executing a method.
      def self.execute(*command, &block)
        new(*command).execute(&block)
      end

      def initialize(*command)
        @options = command.last.is_a?(Hash) ? command.pop : {}
        @command = command
        @logger  = Log4r::Logger.new("vagrant::util::subprocess")
      end

      def execute
        # Get the timeout, if we have one
        timeout = @options[:timeout]
        workdir = @options[:workdir] || Dir.pwd

        # Build the ChildProcess
        @logger.info("Starting process: #{@command.inspect}")
        process = ChildProcess.build(*@command)

        # Create the pipes so we can read the output in real time as
        # we execute the command.
        stdout, stdout_writer = IO.pipe
        stderr, stderr_writer = IO.pipe
        process.io.stdout = stdout_writer
        process.io.stderr = stderr_writer
        process.duplex = true

        # Set the environment on the process if we must
        if @options[:env]
          @options[:env].each do |k, v|
            process.environment[k] = v
          end
        end

        # Start the process
        begin
          Dir.chdir(workdir) do
            process.start
          end
        rescue ChildProcess::LaunchError
          # Raise our own version of the error so that users of the class
          # don't need to be aware of ChildProcess
          raise LaunchError
        end

        # Make sure the stdin does not buffer
        process.io.stdin.sync = true

        # Close the writer pipes, since we're just reading
        stdout_writer.close
        stderr_writer.close

        # Create a dictionary to store all the output we see.
        io_data = { stdout => "", stderr => "" }

        # Record the start time for timeout purposes
        start_time = Time.now.to_i

        @logger.debug("Selecting on IO")
        while true
          results = IO.select([stdout, stderr], [process.io.stdin], nil, timeout || 5)
          readers, writers = results

          # Check if we have exceeded our timeout
          raise TimeoutExceeded, process.pid if timeout && (Time.now.to_i - start_time) > timeout

          # Check the readers to see if they're ready
          if !readers.empty?
            readers.each do |r|
              # Read from the IO object
              data = read_io(r)

              # We don't need to do anything if the data is empty
              next if data.empty?

              io_name = r == stdout ? :stdout : :stderr
              @logger.debug("#{io_name}: #{data}")

              io_data[r] += data
              yield io_name, data if block_given?
            end
          end

          # Break out if the process exited. We have to do this before
          # attempting to write to stdin otherwise we'll get a broken pipe
          # error.
          break if process.exited?

          # Check the writers to see if they're ready, and notify any listeners
          if !writers.empty?
            yield :stdin, process.io.stdin if block_given?
          end
        end

        # Wait for the process to end.
        begin
          remaining = (timeout || 32000) - (Time.now.to_i - start_time)
          remaining = 0 if remaining < 0
          @logger.debug("Waiting for process to exit. Remaining to timeout: #{remaining}")

          process.poll_for_exit(remaining)
        rescue ChildProcess::TimeoutError
          raise TimeoutExceeded, process.pid
        end

        @logger.debug("Exit status: #{process.exit_code}")

        # Read the final output data, since it is possible we missed a small
        # amount of text between the time we last read data and when the
        # process exited.
        [stdout, stderr].each do |io|
          # Read the extra data, ignoring if there isn't any
          extra_data = read_io(io)
          next if extra_data == ""

          # Log it out and accumulate
          @logger.debug(extra_data)
          io_data[io] += extra_data

          # Yield to any listeners any remaining data
          io_name = io == stdout ? :stdout : :stderr
          yield io_name, extra_data if block_given?
        end

        # Return an exit status container
        return Result.new(process.exit_code, io_data[stdout], io_data[stderr])
      end

      protected

      # Reads data from an IO object while it can, returning the data it reads.
      # When it encounters a case when it can't read anymore, it returns the
      # data.
      #
      # @return [String]
      def read_io(io)
        data = ""

        while true
          begin
            data << io.read_nonblock(1024)
          rescue Exception => e
            # The catch-all rescue here is to support multiple Ruby versions,
            # since we use some Ruby 1.9 specific exceptions.

            breakable = false
            if e.is_a?(EOFError)
              # An `EOFError` means this IO object is done!
              breakable = true
            elsif defined?(IO::WaitReadable) && e.is_a?(IO::WaitReadable)
              # IO::WaitReadable is only available on Ruby 1.9+

              # An IO::WaitReadable means there may be more IO but this
              # IO object is not ready to be read from yet. No problem,
              # we read as much as we can, so we break.
              breakable = true
            elsif e.is_a?(Errno::EAGAIN)
              # Otherwise, we just look for the EAGAIN error which should be
              # all that IO::WaitReadable does in Ruby 1.9.
              breakable = true
            end

            # Break out if we're supposed to. Otherwise re-raise the error
            # because it is a real problem.
            break if breakable
            raise
          end
        end

        data
      end

      # An error which raises when a process fails to start
      class LaunchError < StandardError; end

      # An error which occurs when the process doesn't end within
      # the given timeout.
      class TimeoutExceeded < StandardError
        attr_reader :pid

        def initialize(pid)
          super()
          @pid = pid
        end
      end

      # Container class to store the results of executing a subprocess.
      class Result
        attr_reader :exit_code
        attr_reader :stdout
        attr_reader :stderr

        def initialize(exit_code, stdout, stderr)
          @exit_code = exit_code
          @stdout    = stdout
          @stderr    = stderr
        end
      end
    end
  end
end
