# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "mutex_m"

module VagrantPlugins
  module CommandServe
    module Util
      # Helper class for tracking usage and handling
      # activation and deactivation of usage based
      # on count. Activation is only performed on
      # the first request and deactivation is only
      # performed on the final deactivation.
      class UsageTracker
        include Mutex_m

        def initialize
          super
          @count = 0
        end

        # Activate usage. If a block is provided
        # it will only be executed on initial
        # activation (when count is zero).
        #
        # @yield Optional block to be executed
        # @return [Boolean] true on initial activation
        def activate
          mu_synchronize do
            if @count == 0 && block_given?
              yield
            end
            @count += 1

            return @count == 1
          end
        end

        # Deactivate usage. If a block is provided
        # it will only be exected on final deactivation
        # (when count returns to zero). If the count
        # is already zero, the block will not be
        # executed.
        #
        # @yield Optional block to be executed
        # @return [Boolean] true on final deactivation
        def deactivate
          mu_synchronize do
            # If the count is already zero then
            # we do nothing
            return false if @count == 0

            @count -= 1
            if @count == 0 && block_given?
              yield
            end

            return @count == 0
          end
        end

        # @return [Boolean] usage is active
        def active?
          mu_synchronize { @count > 0 }
        end

        # @return [Boolean] usage is not active
        def inactive?
          !active?
        end
      end
    end
  end
end
