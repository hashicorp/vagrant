module Vagrant
  module Downloaders
    # "Downloads" a file to a temporary file. Basically, this downloader
    # simply does a file copy.
    class File < Base
      def prepare(source_url)
        if !::File.file?(source_url)
          raise Actions::ActionException.new(<<-msg)
The given box does not exist on the file system:

#{source_url}
msg
        end
      end

      def download!(source_url, destination_file)
        FileUtils.cp(source_url, destination_file.path)
      end
    end
  end
end
