module Vagrant
  module Util
    class Experimental
      VALID_FEATURES = [].freeze
      class << self

        # A method for determining if the experimental flag has been enabled
        #
        # @return [Boolean]
        def enabled?
          if !defined?(@_experimental)
            experimental = ENV["VAGRANT_EXPERIMENTAL"].to_s
            if experimental != "0" && !experimental.empty?
              @_experimental = true
            else
              @_experimental = false
            end
          end
          @_experimental
        end

        # A method for Vagrant internals to determine if a given feature
        # has been abled and can be used.
        #
        # @param [String] - An array of strings of features to check against
        # @return [Boolean] - A hash containing the original array and if it is valid
        def feature_enabled?(feature)
          experimental = ENV["VAGRANT_EXPERIMENTAL"].to_s.downcase
          if experimental == "1"
            return true
          elsif VALID_FEATURES.include?(feature) &&
                experimental.split(',').include?(feature)
            return true
          else
            return false
          end
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
