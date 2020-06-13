require "log4r"

module Vagrant
  module Util
    class Numeric

      # Authors Note: This conversion has been borrowed from the ActiveSupport Numeric class
      # Conversion helper constants
      KILOBYTE = 1024
      MEGABYTE = KILOBYTE * 1024
      GIGABYTE = MEGABYTE * 1024
      TERABYTE = GIGABYTE * 1024
      PETABYTE = TERABYTE * 1024
      EXABYTE  = PETABYTE * 1024

      BYTES_CONVERSION_MAP = {KB: KILOBYTE, MB: MEGABYTE, GB: GIGABYTE, TB: TERABYTE,
                              PB: PETABYTE, EB: EXABYTE}

      # Regex borrowed from the vagrant-disksize config class
      SHORTHAND_MATCH_REGEX = /^(?<number>[0-9]+)\s?(?<unit>KB|MB|GB|TB)?$/

      class << self
        LOGGER = Log4r::Logger.new("vagrant::util::numeric")

        # A helper that converts a shortcut string to its bytes representation.
        # The expected format of `str` is essentially: "<Number>XX"
        # Where `XX` is shorthand for KB, MB, GB, TB, PB, or EB. For example, 50 megabytes:
        #
        # str = "50MB"
        #
        # @param [String] - str
        # @return [Integer,nil] - bytes - returns nil if method fails to convert to bytes
        def string_to_bytes(str)
          bytes = nil

          str = str.to_s.strip
          matches = SHORTHAND_MATCH_REGEX.match(str)
          if matches
            number = matches[:number].to_i
            unit = matches[:unit].to_sym

            if BYTES_CONVERSION_MAP.key?(unit)
              bytes = number * BYTES_CONVERSION_MAP[unit]
            else
              LOGGER.error("An invalid unit or format was given, string_to_bytes cannot convert #{str}")
            end
          end

          bytes
        end

        # Rounds actual value to two decimal places
        #
        # @param [Integer] bytes
        # @return [Integer] megabytes - bytes representation in megabytes
        def bytes_to_megabytes(bytes)
          (bytes / MEGABYTE.to_f).round(2)
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
