require 'fileutils'

module Vagrant
  module Downloaders
    # "Downloads" a file to a temporary file. Basically, this downloader
    # simply does a file copy.
    class File < Base
      def self.match?(uri)
        ::File.file?(::File.expand_path(uri))
      end

      def download!(source_url, destination_file)
        raise Errors::DownloaderFileDoesntExist if !::File.file?(::File.expand_path(source_url))

        @ui.info I18n.t("vagrant.downloaders.file.download")
        FileUtils.cp(::File.expand_path(source_url), destination_file.path)
      end
    end
  end
end
