module Vagrant
  module Util
    class Numeric
      # Authors Note: This class has borrowed some code from the ActiveSupport Numeric class

      # Conversion helper constants
      KILOBYTE = 1024
      MEGABYTE = KILOBYTE * 1024
      GIGABYTE = MEGABYTE * 1024
      TERABYTE = GIGABYTE * 1024
      PETABYTE = TERABYTE * 1024
      EXABYTE  = PETABYTE * 1024

      class << self

        # A helper that converts a shortcut string to its bytes representation.
        # The expected format of `str` is essentially: "<Number>XX"
        # Where `XX` is shorthand for KB, MB, GB, TB, PB, or EB. For example, 50 megabytes:
        #
        # str = "50MB"
        #
        # @param [String] - str
        # @return [Integer] - bytes
        def string_to_bytes(str)
          str = str.to_s.strip
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
