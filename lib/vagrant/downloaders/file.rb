module Vagrant
  module Downloaders
    # "Downloads" a file to a temporary file. Basically, this downloader
    # simply does a file copy.
    class File < Base
      def download!(source_url, destination_file)
        FileUtils.cp(source_url, destination_file.path)
      end
    end
  end
end
