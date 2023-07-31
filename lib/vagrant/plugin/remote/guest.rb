# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module Vagrant
  module Plugin
    module Remote
      class Guest < V2::Guest
        attr_accessor :client

        def initialize(*_, **kwargs)
          @client = kwargs.delete(:client)
          if @client.nil?
            raise ArgumentError,
              "Remote client is required for `#{self.class.name}`"
          end
          super
        end

        # @return [Boolean]
        def detect?(machine)
          client = machine.client.guest
          client.detect(machine)
        end
      end
    end
  end
end
