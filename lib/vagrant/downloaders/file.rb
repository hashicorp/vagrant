module Vagrant
  module Downloaders
    # "Downloads" a file to a temporary file. Basically, this downloader
    # simply does a file copy.
    class File < Base
      def self.match?(uri)
        ::File.exists?(uri)
      end

      def prepare(source_url)
        if !::File.file?(source_url)
          return env.error!(:downloader_file_doesnt_exist, :source_url => source_url)
        end
      end

      def download!(source_url, destination_file)
        FileUtils.cp(source_url, destination_file.path)
      end
    end
  end
end
