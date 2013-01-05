module VagrantPlugins
  module ProviderVirtualBox
    module Model
      # Represents a single forwarded port for VirtualBox. This has various
      # helpers and defaults for a forwarded port.
      class ForwardedPort
        # The NAT adapter on which to attach the forwarded port.
        #
        # @return [Integer]
        attr_reader :adapter

        # The unique ID for the forwarded port.
        #
        # @return [String]
        attr_reader :id

        # The protocol to forward.
        #
        # @return [String]
        attr_reader :protocol

        # The port on the guest to be exposed on the host.
        #
        # @return [Integer]
        attr_reader :guest_port

        # The port on the host used to access the port on the guest.
        #
        # @return [Integer]
        attr_reader :host_port

        def initialize(id, host_port, guest_port, options)
          @id         = id
          @guest_port = guest_port
          @host_port  = host_port

          options ||= {}
          @adapter  = options[:adapter] || 1
          @protocol = options[:protocol] || "tcp"
        end
      end
    end
  end
end
