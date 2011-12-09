module Vagrant
  module Downloaders
    # Represents a base class for a downloader. A downloader handles
    # downloading a box file to a temporary file.
    class Base
      include Vagrant::Util

      def initialize(ui)
        @ui = ui
      end

      # Tests whether a URL matches this download. Subclasses must
      # override this and return `true` for any URLs they wish to
      # handle.
      def self.match?(url); false; end

      # Called prior to execution so any error checks can be done
      def prepare(source_url); end

      # Downloads the source file to the destination file. It is up to
      # implementors of this class to handle the logic.
      def download!(source_url, destination_file); end
    end
  end
end
