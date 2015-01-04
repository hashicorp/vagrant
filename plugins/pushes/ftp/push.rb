require "net/ftp"
require "pathname"

require_relative "adapter"

module VagrantPlugins
  module FTPPush
    class Push < Vagrant.plugin("2", :push)
      IGNORED_FILES = %w(. ..).freeze
      DEFAULT_EXCLUDES = %w(.git .hg .svn .vagrant).freeze

      def initialize(*)
        super
        @logger = Log4r::Logger.new("vagrant::pushes::ftp")
      end

      def push
        # Grab files early so if there's an exception or issue, we don't have to
        # wait and close the (S)FTP connection as well
        files = Hash[*all_files.flat_map do |file|
          relative_path = relative_path_for(file, config.dir)
          destination = File.expand_path(File.join(config.destination, relative_path))
          file = File.expand_path(file, env.root_path)
          [file, destination]
        end]

        ftp = "#{config.username}@#{config.host}:#{config.destination}"
        env.ui.info "Uploading #{env.root_path} to #{ftp}"

        connect do |ftp|
          files.each do |local, remote|
            @logger.info "Uploading #{local} => #{remote}"
            ftp.upload(local, remote)
          end
        end
      end

      # Helper method for creating the FTP or SFTP connection.
      # @yield [Adapter]
      def connect(&block)
        klass = config.secure ? SFTPAdapter : FTPAdapter
        ftp = klass.new(config.host, config.username, config.password,
          passive: config.passive)
        ftp.connect(&block)
      end

      # The list of all files that should be pushed by this push. This method
      # only returns **files**, not folders or symlinks!
      # @return [Array<String>]
      def all_files
        files = glob("#{config.dir}/**/*") + includes_files
        filter_excludes!(files, config.excludes)
        files.reject! { |f| !File.file?(f) }
        files
      end

      # The list of files to include in addition to those specified in `dir`.
      # @return [Array<String>]
      def includes_files
        includes = config.includes.flat_map do |i|
          path = absolute_path_for(i, config.dir)
          [path, "#{path}/**/*"]
        end

        glob("{#{includes.join(",")}}")
      end

      # Filter the excludes out of the given list. This method modifies the
      # given list in memory!
      #
      # @param [Array<String>] list
      #   the filepaths
      # @param [Array<String>] excludes
      #   the exclude patterns or files
      def filter_excludes!(list, excludes)
        excludes = Array(excludes)
        excludes = excludes + DEFAULT_EXCLUDES
        excludes = excludes.flat_map { |e| [e, "#{e}/*"] }

        list.reject! do |file|
          basename = relative_path_for(file, config.dir)

          # Handle the special case where the file is outside of the working
          # directory...
          if basename.start_with?("../")
            basename = file
          end

          excludes.any? { |e| File.fnmatch?(e, basename, File::FNM_DOTMATCH) }
        end
      end

      # Get the list of files that match the given pattern.
      # @return [Array<String>]
      def glob(pattern)
        Dir.glob(pattern, File::FNM_DOTMATCH).sort.reject do |file|
          IGNORED_FILES.include?(File.basename(file))
        end
      end

      # The absolute path to the given `path` and `parent`, unless the given
      # path is absolute.
      # @return [String]
      def absolute_path_for(path, parent)
        path = Pathname.new(path)
        return path if path.absolute?
        File.expand_path(path, parent)
      end

      # The relative path from the given `parent`. If files exist on another
      # device, this will probably blow up.
      # @return [String]
      def relative_path_for(path, parent)
        Pathname.new(path).relative_path_from(Pathname.new(parent)).to_s
      rescue ArgumentError
        return path
      end
    end
  end
end
