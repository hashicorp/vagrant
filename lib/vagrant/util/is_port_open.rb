require "socket"
require "timeout"

module Vagrant
  module Util
    # Contains the method {#is_port_open?} to check if a port is open
    # (listening) or closed (not in use). This method isn't completely
    # fool-proof, but it works enough of the time to be useful.
    module IsPortOpen
      # Checks if a port is open (listening) on a given host and port.
      #
      # @param [String] host Hostname or IP address.
      # @param [Integer] port Port to check.
      # @return [Boolean] `true` if the port is open (listening), `false`
      #   otherwise.
      def is_port_open?(host, port)
        # We wrap this in a timeout because once in awhile the TCPSocket
        # _will_ hang, but this signals that the port is closed.
        Timeout.timeout(1) do
          # Attempt to make a connection
          s = TCPSocket.new(host, port)

          # A connection was made! Properly clean up the socket, not caring
          # at all if any exception is raised, because we already know the
          # result.
          s.close rescue nil

          # The port is open if we reached this point, since we were able
          # to connect.
          return true
        end
      rescue Timeout::Error, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, \
             Errno::ENETUNREACH, Errno::EACCES, Errno::ENOTCONN, \
             Errno::EADDRNOTAVAIL
        # Any of the above exceptions signal that the port is closed.
        return false
      end
    end
  end
end
