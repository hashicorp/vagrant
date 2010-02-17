module Vagrant
  module Actions
    class Package < Base
      def execute!(name=Vagrant.config.package.name, to=FileUtils.pwd)
        folder = FileUtils.mkpath(File.join(to, name))
        tar_path = "#{folder}#{Vagrant.config.package.extension}"

        logger.info "Packaging VM into #{tar_path} ..."
        compress(Dir["#{folder}/*.*"], tar_path)

        logger.info "Removing working directory ..."
        FileUtils.rm_r(folder)

        tar_path
      end

      def compress(files_to_compress, compressed_file_name)
        delimiter = Vagrant.config.package.delimiter
        Zlib::GzipWriter.open(compressed_file_name) do |gz|
          files_to_compress.each do  |file|
            # Delimit the files, and guarantee new line for next file if not the first
            gz.write "#{delimiter}#{File.basename(file)}#{delimiter}"
            File.open(file).each { |line| gz.write(line) }
          end
        end
      end
    end
  end
end
