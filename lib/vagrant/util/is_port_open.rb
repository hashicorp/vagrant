require "socket"

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
        begin
          Socket.tcp(host, port, connect_timeout: 0.1).close
          true
        rescue Errno::ETIMEDOUT, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, \
            Errno::ENETUNREACH, Errno::EACCES, Errno::ENOTCONN, Errno::EALREADY
          false
        end
      end

      extend IsPortOpen
    end
  end
end
