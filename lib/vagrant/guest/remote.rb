# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module Vagrant
  class Guest
    # This module enables Guests for server mode
    module Remote

      # Add an attribute accesor for the client
      # when applied to the Guest class
      def self.prepended(klass)
        klass.class_eval do
          attr_accessor :client
        end
      end

      def initialize(machine, guests, capabilities)
        @machine = machine
        @client = machine.client.guest
        @logger = Log4r::Logger.new("vagrant::guest")
      end

      def initialize_capabilities!(host, hosts, capabilities, *args)
        # no-op
      end

      def detect!
        # no-op
        # This operation not happen in Ruby, instead rely
        # on getting the guest from the remote machine
      end

      # Executes the capability with the given name, optionally passing more
      # arguments onwards to the capability. If the capability returns a value,
      # it will be returned.
      #
      # @param [Symbol] cap_name Name of the capability
      def capability(cap_name, *args)
        @logger.debug("running remote guest capability #{cap_name} with args #{args}")
        if !client.has_capability?(cap_name)
          raise Errors::GuestCapabilityNotFound,
          cap:  cap_name.to_s,
          guest: name
        end
        client.capability(cap_name, @machine.to_proto, *args)
      end

      # Tests whether the given capability is possible.
      #
      # @param [Symbol] cap_name Capability name
      # @return [Boolean]
      def capability?(cap_name)
        @logger.debug("checking for remote guest capability #{cap_name}")
        client.has_capability?(cap_name)
      end

      # @return [Boolean]
      def ready?
        # A remote guest is always "ready". That is, guest detection has already
        # completed on the go side. So, at this stage and the communicator is 
        # certainly available.
        true
      end

      # Returns the specified or detected guest type name.
      #
      # @return [Symbol]
      def name
        client.name
      end

      # Returns the parent of the guest.
      #
      # @return [String]
      def parent
        client.parent
      end

      def to_proto
        client.proto
      end
    end
  end
end
