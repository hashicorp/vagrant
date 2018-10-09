require 'optparse'
require "rubygems/package"

module VagrantPlugins
  module CommandUpload
    class Command < Vagrant.plugin("2", :command)

      VALID_COMPRESS_TYPES = [:tgz, :zip].freeze

      def self.synopsis
        "upload to machine via communicator"
      end

      def execute
        options = {}

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant upload [options] <source> [destination] [name|id]"
          o.separator ""
          o.separator "Options:"
          o.separator ""

          o.on("-t", "--temporary", "Upload source to temporary directory") do |t|
            options[:temporary] = t
          end

          o.on("-c", "--compress", "Use gzip compression for upload") do |c|
            options[:compress] = c
          end

          o.on("-C", "--compression-type=TYPE", "Type of compression to use (#{VALID_COMPRESS_TYPES.join(", ")})") do |c|
            options[:compression_type] = c.to_sym
            options[:compress] = true
          end
        end

        argv = parse_options(opts)
        return if !argv

        case argv.size
        when 3
          source, destination, guest = argv
        when 2, 1
          source = argv[0]
          if @env.active_machines.map(&:first).map(&:to_s).include?(argv[1])
            guest = argv[1]
          else
            destination = argv[1]
          end
        else
          raise Vagrant::Errors::CLIInvalidUsage, help: opts.help.chomp
        end

        # NOTE: We do this to handle paths on Windows like: "..\space dir\"
        # because the final separater acts to escape the quote and ends up
        # in the source value.
        source = source.sub(/["']$/, "")
        destination ||= File.basename(source)

        if File.file?(source)
          type = :file
        elsif File.directory?(source)
          type = :directory
        else
          raise Vagrant::Errors::UploadSourceMissing,
            source: source
        end

        with_target_vms(guest, single_target: true) do |machine|
          if options[:temporary]
            if !machine.guest.capability?(:create_tmp_path)
              raise Vagrant::Errors::UploadMissingTempCapability
            end
            extension = File.extname(source) if type == :file
            destination = machine.guest.capability(:create_tmp_path, type: type, extension: extension)
          end

          if options[:compress]
            compression_setup!(machine, options)
            @env.ui.info(I18n.t("vagrant.commands.upload.compress",
              source: source,
              type: options[:compression_type]
            ))
            destination_decompressed = destination
            destination = machine.guest.capability(:create_tmp_path, type: :file, extension: ".#{options[:compression_type]}")
            source_display = source
            source = options[:compression_type] == :zip ? compress_source_zip(source) : compress_source_tgz(source)
          end

          @env.ui.info(I18n.t("vagrant.commands.upload.start",
            source: source,
            destination: destination
          ))

          # If the source is a directory, attach a `/.` to the end so we
          # upload the contents to the destination instead of within a
          # folder at the destination
          if File.directory?(source) && !source.end_with?(".")
            upload_source = File.join(source, ".")
          else
            upload_source = source
          end

          machine.communicate.upload(upload_source, destination)

          if options[:compress]
            @env.ui.info(I18n.t("vagrant.commands.upload.decompress",
              destination: destination_decompressed,
              type: options[:compression_type]
            ))
            machine.guest.capability(options[:decompression_method], destination, destination_decompressed, type: type)
            destination = destination_decompressed
            FileUtils.rm(source)
            source = source_display
          end
        end

        @env.ui.info(I18n.t("vagrant.commands.upload.complete",
          source: source,
          destination: destination
        ))

        # Success, exit status 0
        0
      end

      # Setup compression options and validate host and guest have capability
      # to handle compression
      #
      # @param [Vagrant::Machine] machine Vagrant guest machine
      # @param [Hash] options Command options
      def compression_setup!(machine, options)
        if !options[:compression_type]
          if machine.guest.capability_host_chain.first[0] == :windows
            options[:compression_type] = :zip
          else
            options[:compression_type] = :tgz
          end
        end
        if !VALID_COMPRESS_TYPES.include?(options[:compression_type])
          raise Vagrant::Errors::UploadInvalidCompressionType,
            type: options[:compression_type],
            valid_types: VALID_COMPRESS_TYPES.join(", ")
        end
        options[:decompression_method] = "decompress_#{options[:compression_type]}".to_sym
        if !machine.guest.capability?(options[:decompression_method])
          raise Vagrant::Errors::UploadMissingExtractCapability,
            type: options[:compression_type]
        end
      end

      # Compress path using zip into temporary file
      #
      # @param [String] path Path to compress
      # @return [String] path to compressed file
      def compress_source_zip(path)
        require "zip"
        zipfile = Tempfile.create(["vagrant", ".zip"])
        zipfile.close
        if File.file?(path)
          source_items = [path]
        else
          source_items = Dir.glob(File.join(path, "**", "**", "*"))
        end
        c_dir = nil
        Zip::File.open(zipfile.path, Zip::File::CREATE) do |zip|
          source_items.each do |source_item|
            next if File.directory?(source_item)
            trim_item = source_item.sub(path, "").sub(%r{^[/\\]}, "")
            dirname = File.dirname(trim_item)
            zip.mkdir dirname if c_dir != dirname
            c_dir = dirname
            zip.get_output_stream(trim_item) do |f|
              source_file = File.open(source_item, "rb")
              while data = source_file.read(2048)
                f.write(data)
              end
            end
          end
        end
        zipfile.path
      end

      # Compress path using tar and gzip into temporary file
      #
      # @param [String] path Path to compress
      # @return [String] path to compressed file
      def compress_source_tgz(path)
        tarfile = Tempfile.create(["vagrant", ".tar"])
        tarfile.close
        tarfile = File.open(tarfile.path, "wb+")
        tgzfile = Tempfile.create(["vagrant", ".tgz"])
        tgzfile.close
        tgzfile = File.open(tgzfile.path, "wb")
        tar = Gem::Package::TarWriter.new(tarfile)
        tgz = Zlib::GzipWriter.new(tgzfile)
        if File.file?(path)
          tar.add_file(File.basename(path), File.stat(path).mode) do |io|
            File.open(path, "rb") do |file|
              while bytes = file.read(4096)
                io.write(bytes)
              end
            end
          end
        else
          Dir.glob(File.join(path, "**/**/*")).each do |item|
            rel_path = item.sub(path, "")
            item_mode = File.stat(item).mode

            if File.directory?(item)
              tar.mkdir(rel_path, item_mode)
            else
              tar.add_file(rel_path, item_mode) do |io|
                File.open(item, "rb") do |file|
                  while bytes = file.read(4096)
                    io.write(bytes)
                  end
                end
              end
            end
          end
        end
        tar.close
        tarfile.rewind
        while bytes = tarfile.read(4096)
          tgz.write bytes
        end
        tgz.close
        tgzfile.close
        tarfile.close
        File.delete(tarfile.path)
        tgzfile.path
      end
    end
  end
end
