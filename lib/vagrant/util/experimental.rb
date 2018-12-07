module Vagrant
  module Util
    class Experimental
      class << self
        # A method for determining if the experimental flag has been enabled with
        # any features
        #
        # @return [Boolean]
        def enabled?
          if !defined?(@_experimental)
            experimental = features_requested
            if experimental.size >= 1 && experimental.first != "0"
              @_experimental = true
            else
              @_experimental = false
            end
          end
          @_experimental
        end

        # A method for determining if all experimental features have been enabled
        # by either a global enabled value "1" or all features explicitly enabled.
        #
        # @return [Boolean]
        def global_enabled?
          if !defined?(@_global_enabled)
            experimental = features_requested
            if experimental.size == 1 && experimental.first == "1"
              @_global_enabled = true
            else
              @_global_enabled = false
            end
          end
          @_global_enabled
        end

        # A method for Vagrant internals to determine if a given feature
        # has been abled by the user, is a valid feature flag and can be used.
        #
        # @param [String] feature
        # @return [Boolean] - A hash containing the original array and if it is valid
        def feature_enabled?(feature)
          experimental = features_requested
          feature = feature.to_s

          return global_enabled? || experimental.include?(feature)
        end

        # Returns the features requested for the experimental flag
        #
        # @return [Array] - Returns an array of requested experimental features
        def features_requested
          if !defined?(@_requested_features)
            @_requested_features = ENV["VAGRANT_EXPERIMENTAL"].to_s.downcase.split(',')
          end
          @_requested_features
        end

        # A function to guard experimental blocks of code from being executed
        #
        # @param [Array] features - Array of features to guard a method with
        # @param [Block] block - Block of ruby code to be guarded against
        def guard_with(*features, &block)
          yield if block_given? && features.any? {|f| feature_enabled?(f)}
        end

        # @private
        # Reset the cached values for platform. This is not considered a public
        # API and should only be used for testing.
        def reset!
          instance_variables.each(&method(:remove_instance_variable))
        end
      end
    end
  end
end
