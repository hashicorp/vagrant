module Vagrant
  module Actions
    class Unpackage < Base
      def initialize(vm, *args)
        super vm
        @package_file_path = args[0]
      end

      def execute!
        # Exit if folder of same name exists
        # TODO provide a way for them to specify the directory name
        error_and_exit(<<-error) if File.exists?(new_base_dir)
The directory `#{file_name_without_extension}` already exists under #{Vagrant.config[:vagrant][:home]}. Please
remove it, rename your packaged VM file, or (TODO) specifiy an
alternate directory
error

        logger.info "Creating working new base directory: #{new_base_dir} ..."
        FileUtils.mkpath(new_base_dir)

        logger.info "Decompressing the packaged VM: #{package_file_path} to: #{new_base_dir}..."
        decompress_to new_base_dir

        #Return the ovf file for importation
        Dir["#{new_base_dir}/*.ovf"].first
      end

      def new_base_dir
        File.join(Vagrant.config[:vagrant][:home], file_name_without_extension)
      end

      def file_name_without_extension
        File.basename(package_file_path, '.*')
      end

      def package_file_path
        File.expand_path(@package_file_path)
      end

      def decompress_to(dir, file_delimeter=Vagrant.config[:package][:delimiter_regex])
        file = nil
        Zlib::GzipReader.open(package_file_path) do |gz|
          begin
            gz.each_line do |line|

              # If the line is a file delimiter create new file and write to it
              if line =~ file_delimeter

                #Write the the part of the line belonging to the previous file
                if file
                  file.write $1
                  file.close
                end

                #Open a new file with the name contained in the delimiter
                file = File.open(File.join(dir, $2), 'w')

                #Write the rest of the line to the new file
                file.write $3
              else
                file.write line
              end
            end
          ensure
            file.close if file
          end
        end
      end
    end
  end
end
