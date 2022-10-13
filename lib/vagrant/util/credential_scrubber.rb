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

      # Remove sensitive information from string
      #
      # @param [String] string
      # @return [String]
      def self.desensitize(string)
        string = string.to_s.dup
        sensitive_strings.each do |remove|
          string.gsub!(/(\W|^)#{Regexp.escape(remove)}(\W|$)/, "\\1#{REPLACEMENT_TEXT}\\2")
        end
        string
      end

      # Register a sensitive string to be scrubbed
      def self.sensitive(string)
        string = string.to_s.dup
        if string.length > 0
          sensitive_strings.push(string).uniq!
        end
        nil
      end

      # Deregister a sensitive string and allow output
      def self.unsensitive(string)
        sensitive_strings.delete(string)
        nil
      end

      # @return [Array<string>]
      def self.sensitive_strings
        if !defined?(@_sensitive_strings)
          @_sensitive_strings = []
        end
        @_sensitive_strings
      end

      # @private
      # Reset the cached values for scrubber. This is not considered a public
      # API and should only be used for testing.
      def self.reset!
        instance_variables.each(&method(:remove_instance_variable))
      end
    end
  end
end
