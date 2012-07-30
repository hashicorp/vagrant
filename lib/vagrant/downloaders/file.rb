require 'fileutils'

module Vagrant
  module Downloaders
    # "Downloads" a file to a temporary file. Basically, this downloader
    # simply does a file copy.
    class File < Base
      def self.match?(url)
        uri = URI.parse(url)

        [nil, 'file'].include?(uri.scheme)
      end

      def prepare(source_url)
        file_path = URI.parse(source_url).path

        raise Errors::DownloaderFileDoesntExist if !::File.file?(::File.expand_path(file_path))
      end

      def download!(source_url, destination_file)
        file_path = URI.parse(source_url).path

        @ui.info I18n.t("vagrant.downloaders.file.download")
        FileUtils.cp(::File.expand_path(file_path), destination_file.path)
      end
    end
  end
end
