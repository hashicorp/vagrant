module Vagrant
  module Downloaders
    # Represents a base class for a downloader. A downloader handles
    # downloading a box file to a temporary file.
    class Base
      include Vagrant::Util

      # Downloads the source file to the destination file. It is up to
      # implementors of this class to handle the logic.
      def download!(source_url, destination_file); end
    end
  end
end