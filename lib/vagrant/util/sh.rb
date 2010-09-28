module Vagrant
  module Util
    module Sh
      # Runs the given shell command, collecting STDERR and STDOUT
      # into a single string and returning it. After this method,
      # `$?` will be set to a `Process::Status` object.
      #
      # @param [String] command Command to run
      # @return [Array] An array of `[output, status]` where status is `Process::Status`
      def sh(command, *args)
        # Use a pipe to execute the given command
        rd, wr = IO.pipe
        pid = fork do
          rd.close
          $stdout.reopen wr
          $stderr.reopen wr
          exec(command, *args) rescue nil
          exit! 1 # Should never reach this point
        end

        # Close our end of the writer pipe, read the output until
        # its over, and wait for the process to end.
        wr.close
        out = ""
        out << rd.read until rd.eof?
        _, status = Process.wait2(-1, Process::WNOHANG)

        # Finally, return the result
        [out, status]
      end
    end
  end
end
