module Vagrant
  module Downloaders
    # Represents a base class for a downloader. A downloader handles
    # downloading a box file to a temporary file.
    class Base
      include Vagrant::Util

      # The environment which this downloader is operating.
      attr_reader :env

      def initialize(env)
        @env = env
      end

      # Called prior to execution so any error checks can be done
      def prepare(source_url); end

      # Downloads the source file to the destination file. It is up to
      # implementors of this class to handle the logic.
      def download!(source_url, destination_file); end
    end
  end
end
