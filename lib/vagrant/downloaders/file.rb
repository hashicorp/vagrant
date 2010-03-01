module Vagrant
  module Downloaders
    # "Downloads" a file to a temporary file. Basically, this downloader
    # simply does a file copy.
    class File < Base
      BUFFERSIZE = 1048576 # 1 MB

      def download!(source_url, destination_file)
        # For now we read the contents of one into a buffer
        # and copy it into the other. In the future, we should do
        # a system-level file copy (FileUtils.cp).
        open(source_url) do |f|
          loop do
            break if f.eof?
            destination_file.write(f.read(BUFFERSIZE))
          end
        end
      end
    end
  end
end