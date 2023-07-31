# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    module Util
      # Requires a broker to be set when initializing an
      # instance and adds an accessor to the broker
      module HasBroker
        def broker
          @broker
        end

        def initialize(*args, **opts, &block)
          @broker = opts.delete(:broker)
          raise ArgumentError,
            "Expected `Broker' to be provided" if @broker.nil?

          sup = self.method(:initialize).super_method
          if sup.parameters.empty?
            super()
          elsif !opts.empty? && sup.parameters.detect{ |type, _| type == :keyreq || type == :keyrest }
            super
          else
            super(*args, &block)
          end
        end
      end
    end
  end
end
