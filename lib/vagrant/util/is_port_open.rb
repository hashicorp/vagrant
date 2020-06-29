require "socket"

module Vagrant
  module Util
    # Contains the method {#is_port_open?} to check if a port is open
    # (listening) or closed (not in use). This method isn't completely
    # fool-proof, but it works enough of the time to be useful.
    module IsPortOpen
      # Checks if a port is open (listening) on a given host and port.
      # https://stackoverflow.com/a/3473208
      #
      # @param [String] host Hostname or IP address.
      # @param [Integer] port Port to check.
      # @return [Boolean] `true` if the port is open (listening), `false`
      #   otherwise.
      def is_port_open?(host, port)
        s = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
        sa = Socket.sockaddr_in(port, host)

        begin
          s.connect_nonblock(sa)
        rescue Errno::EINPROGRESS
          if ::IO.select(nil, [s], nil, 0.1)
            begin
              s.connect_nonblock(sa)
            rescue Errno::EISCONN
              return true
            rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
              return false
            end
          end
        end

        false
      end

      extend IsPortOpen
    end
  end
end
