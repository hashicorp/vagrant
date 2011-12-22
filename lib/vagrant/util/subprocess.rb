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
        @command = command
        @logger  = Log4r::Logger.new("vagrant::util::subprocess")
      end

      def execute
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

        # Start the process
        begin
          process.start
        rescue Exception => e
          if defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
            if e.is_a?(NativeException)
              # This usually means that the process failed to start, so we
              # raise that error.
              raise ProcessFailedToStart
            end
          end

          raise
        end

        # Make sure the stdin does not buffer
        process.io.stdin.sync = true

        # Close the writer pipes, since we're just reading
        stdout_writer.close
        stderr_writer.close

        # Create a dictionary to store all the output we see.
        io_data = { stdout => "", stderr => "" }

        @logger.debug("Selecting on IO")
        while true
          results = IO.select([stdout, stderr], [process.io.stdin], nil, 5)
          readers, writers = results

          # Check the readers to see if they're ready
          if !readers.empty?
            readers.each do |r|
              # Read from the IO object
              data = read_io(r)

              # We don't need to do anything if the data is empty
              next if data.empty?

              io_name = r == stdout ? :stdout : :stderr
              @logger.debug(data)

              if io_name == :stderr && io_data[r] == "" && data =~ /Errno::ENOENT/
                # This is how we detect that a process failed to start on
                # Linux. Hacky, but it works fairly well.
                raise ProcessFailedToStart
              end

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
        process.poll_for_exit(32000)
        @logger.debug("Exit status: #{process.exit_code}")

        # Read the final output data, since it is possible we missed a small
        # amount of text between the time we last read data and when the
        # process exited.
        [stdout, stderr].each do |io|
          extra_data = read_io(io)
          @logger.debug(extra_data)
          io_data[io] += extra_data

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
          rescue IO::WaitReadable, EOFError
            # An IO::WaitReadable means there may be more IO but this
            # IO object is not ready to be read from yet. No problem,
            # we read as much as we can, so we break.

            # An `EOFError`, on the other hand, means this IO object
            # is done! We still just break out.
            break
          end
        end

        data
      end

      # An error which occurs when a process fails to start.
      class ProcessFailedToStart < StandardError; end

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
