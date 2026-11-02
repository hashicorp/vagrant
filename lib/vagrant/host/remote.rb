# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module Vagrant
  class Host
    # This module enables Host for server mode
    module Remote

      # Add an attribute accesor for the client
      # when applied to the Guest class
      def self.prepended(klass)
        klass.class_eval do
          attr_accessor :client
        end
      end

      # @param [] host client
      # @param hosts - unused
      # @param capabilities - unused
      # @param [Vagrant::Environment]
      def initialize(host, hosts, capabilities, env)
        @env = env
        @client = host
        @logger = Log4r::Logger.new("vagrant::host")
      end

      def initialize_capabilities!(host, hosts, capabilities, *args)
        # no-op
      end

      # Executes the capability with the given name, optionally passing more
      # arguments onwards to the capability. If the capability returns a value,
      # it will be returned.
      #
      # @param [Symbol] cap_name Name of the capability
      def capability(cap_name, *args)
        @logger.debug("running remote host capability #{cap_name} with args #{args}")
        client.capability(cap_name, *args)
      end

      # Tests whether the given capability is possible.
      #
      # @param [Symbol] cap_name Capability name
      # @return [Boolean]
      def capability?(cap_name)
        @logger.debug("checking for remote host capability #{cap_name}")
        client.has_capability?(cap_name)
      end

      def to_proto
        client.proto
      end
    end
  end
end
