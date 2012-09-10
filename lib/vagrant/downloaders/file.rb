require 'fileutils'
require 'uri'

module Vagrant
  module Downloaders
    # "Downloads" a file to a temporary file. Basically, this downloader
    # simply does a file copy.
    class File < Base
      def self.match?(uri)
        extracted = URI.extract(uri, "file")

        # We match if we got a file URI. It doesn't matter here if the file
        # doesn't exist because we check again later as well.
        return true if extracted && extracted.include?(uri)

        # Otherwise we match if the file exists
        return ::File.file?(::File.expand_path(uri))
      end

      def download!(source_url, destination_file)
        raise Errors::DownloaderFileDoesntExist if !::File.file?(::File.expand_path(source_url))

        @ui.info I18n.t("vagrant.downloaders.file.download")
        FileUtils.cp(::File.expand_path(source_url), destination_file.path)
      end
    end
  end
end
