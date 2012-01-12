require 'fileutils'

module Vagrant
  module Downloaders
    # "Downloads" a file to a temporary file. Basically, this downloader
    # simply does a file copy.
    class File < Base
      def self.match?(uri)
        ::File.exists?(uri)
      end

      def prepare(source_url)
        raise Errors::DownloaderFileDoesntExist if !::File.file?(::File.expand_path(source_url))
      end

      def download!(source_url, destination_file)
        @ui.info I18n.t("vagrant.downloaders.file.download")
        FileUtils.cp(::File.expand_path(source_url), destination_file.path)
      end
    end
  end
end
