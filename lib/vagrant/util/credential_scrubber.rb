module Vagrant
  module Util
    # Utility class to remove credential information from strings
    class CredentialScrubber
      # String used to replace credential information
      REPLACEMENT_TEXT = "*****".freeze

      # Attempt to remove detected credentials from string
      #
      # @param [String] string
      # @return [String]
      def self.scrub(string)
        string = url_scrubber(string)
      end

      # Detect URLs and remove any embedded credentials
      #
      # @param [String] string
      # @return [String]
      def self.url_scrubber(string)
        string.gsub(%r{(ftp|https?)://[^\s]+@[^\s]+}) do |address|
          uri = URI.parse(address)
          uri.user = uri.password = REPLACEMENT_TEXT
          uri.to_s
        end
      end
    end
  end
end
