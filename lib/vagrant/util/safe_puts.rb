module Vagrant
  module Util
    # This module provides a `safe_puts` method which outputs to
    # the given IO object, and rescues any broken pipe errors and
    # ignores them. This is useful in cases where you're outputting
    # to stdout, for example, and the stdout is closed, but you want to
    # keep running.
    module SafePuts
      # Uses `puts` on the given IO object and safely ignores any
      # Errno::EPIPE.
      #
      # @param [String] message Message to output.
      # @param [Hash] opts Options hash.
      def safe_puts(message=nil, opts=nil)
        message ||= ""
        opts = {
          io: $stdout,
          printer: :puts
        }.merge(opts || {})

        begin
          opts[:io].send(opts[:printer], message)
        rescue Errno::EPIPE
          # This is what makes this a `safe` puts.
          return
        end
      end
    end
  end
end

