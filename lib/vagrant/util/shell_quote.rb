module Vagrant
  module Util
    module ShellQuote
      # This will auto-escape the text with the given quote mark type.
      #
      # @param [String] text Text to escape
      # @param [String] quote The quote character, such as "
      def self.escape(text, quote)
        text.gsub(/#{quote}/) do |m|
          "#{m}\\#{m}#{m}"
        end
      end
    end
  end
end
