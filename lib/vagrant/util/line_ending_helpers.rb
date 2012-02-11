module Vagrant
  module Util
    module LineEndingHelpers
      # Converts line endings to unix-style line endings in the
      # given string.
      #
      # @param [String] string Original string
      # @return [String] The fixed string
      def dos_to_unix(string)
        string.gsub("\r\n", "\n")
      end
    end
  end
end
