require 'thread'

require 'childprocess'
require 'log4r'

require 'vagrant/util/platform'
require 'vagrant/util/safe_chdir'
require 'vagrant/util/which'

module Vagrant
  module Util
    # Execute a command in a subprocess, gathering the results and
    # exit status.
    #
    # This class also allows you to read the data as it is outputted
    # from the subprocess in real time, by simply passing a block to
    # the execute method.
    class Subprocess
      # The chunk size for reading from subprocess IO.
      READ_CHUNK_SIZE = 4096

      # Convenience method for executing a method.
      def self.execute(*command, &block)
        new(*command).execute(&block)
      end

      def initialize(*command)
        progname = command[0]
        @options = command.last.is_a?(Hash) ? command.pop : {}
        @command = command
        @command[0] = Which.which(@command[0]) if !File.file?(@command[0])
        if !@command[0]
          raise Errors::CommandUnavailableWindows, file: progname if Platform.windows?
          raise Errors::CommandUnavailable, file: progname
        end

        @logger  = Log4r::Logger.new("vagrant::util::subprocess")
      end

      def execute
        # Get the timeout, if we have one
        timeout = @options[:timeout]

        # Get the working directory
        workdir = @options[:workdir] || Dir.pwd

        # Get what we're interested in being notified about
        notify  = @options[:notify] || []
        notify  = [notify] if !notify.is_a?(Array)
        if notify.empty? && block_given?
          # If a block is given, subscribers must be given, otherwise the
          # block is never called. This is usually NOT what you want, so this
          # is an error.
          message = "A list of notify subscriptions must be given if a block is given"
          raise ArgumentError, message
        end

        # Let's get some more useful booleans that we access a lot so
        # we're not constantly calling an `include` check
        notify_table = {}
        notify_table[:stderr] = notify.include?(:stderr)
        notify_table[:stdout] = notify.include?(:stdout)
        notify_stdin  = notify.include?(:stdin)

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
          SafeChdir.safe_chdir(workdir) do
            process.start
          end
        rescue ChildProcess::LaunchError => ex
          # Raise our own version of the error so that users of the class
          # don't need to be aware of ChildProcess
          raise LaunchError.new(ex.message)
        end

        # Make sure the stdin does not buffer
        process.io.stdin.sync = true

        if RUBY_PLATFORM != "java"
          # On Java, we have to close after. See down the method...
          # Otherwise, we close the writers right here, since we're
          # not on the writing side.
          stdout_writer.close
          stderr_writer.close
        end

        # Create a dictionary to store all the output we see.
        io_data = { :stdout => "", :stderr => "" }

        # Record the start time for timeout purposes
        start_time = Time.now.to_i

        @logger.debug("Selecting on IO")
        while true
          writers = notify_stdin ? [process.io.stdin] : []
          results = IO.select([stdout, stderr], writers, nil, timeout || 0.1)
          results ||= []
          readers = results[0]
          writers = results[1]

          # Check if we have exceeded our timeout
          raise TimeoutExceeded, process.pid if timeout && (Time.now.to_i - start_time) > timeout

          # Check the readers to see if they're ready
          if readers && !readers.empty?
            readers.each do |r|
              # Read from the IO object
              data = read_io(r)

              # We don't need to do anything if the data is empty
              next if data.empty?

              io_name = r == stdout ? :stdout : :stderr
              @logger.debug("#{io_name}: #{data.chomp}")

              io_data[io_name] += data
              yield io_name, data if block_given? && notify_table[io_name]
            end
          end

          # Break out if the process exited. We have to do this before
          # attempting to write to stdin otherwise we'll get a broken pipe
          # error.
          break if process.exited?

          # Check the writers to see if they're ready, and notify any listeners
          if writers && !writers.empty?
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
          io_name = io == stdout ? :stdout : :stderr
          io_data[io_name] += extra_data
          @logger.debug("#{io_name}: #{extra_data.chomp}")

          # Yield to any listeners any remaining data
          yield io_name, extra_data if block_given?
        end

        if RUBY_PLATFORM == "java"
          # On JRuby, we need to close the writers after the process,
          # for some reason. See GH-711.
          stdout_writer.close
          stderr_writer.close
        end

        # Return an exit status container
        return Result.new(process.exit_code, io_data[:stdout], io_data[:stderr])
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
            if Platform.windows?
              # Windows doesn't support non-blocking reads on
              # file descriptors or pipes so we have to get
              # a bit more creative.

              # Check if data is actually ready on this IO device.
              # We have to do this since `readpartial` will actually block
              # until data is available, which can cause blocking forever
              # in some cases.
              results = IO.select([io], nil, nil, 0.1)
              break if !results || results[0].empty?

              # Read!
              data << io.readpartial(READ_CHUNK_SIZE)
            else
              # Do a simple non-blocking read on the IO object
              data << io.read_nonblock(READ_CHUNK_SIZE)
            end
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
