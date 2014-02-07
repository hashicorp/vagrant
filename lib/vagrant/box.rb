require 'fileutils'
require "tempfile"

require "json"
require "log4r"

require "vagrant/box_metadata"
require "vagrant/util/downloader"
require "vagrant/util/platform"
require "vagrant/util/safe_chdir"
require "vagrant/util/subprocess"

module Vagrant
  # Represents a "box," which is a package Vagrant environment that is used
  # as a base image when creating a new guest machine.
  class Box
    include Comparable

    # The box name. This is the logical name used when adding the box.
    #
    # @return [String]
    attr_reader :name

    # This is the provider that this box is built for.
    #
    # @return [Symbol]
    attr_reader :provider

    # The version of this box.
    #
    # @return [String]
    attr_reader :version

    # This is the directory on disk where this box exists.
    #
    # @return [Pathname]
    attr_reader :directory

    # This is the metadata for the box. This is read from the "metadata.json"
    # file that all boxes require.
    #
    # @return [Hash]
    attr_reader :metadata

    # This is the URL to the version info and other metadata for this
    # box.
    #
    # @return [String]
    attr_reader :metadata_url

    # This is used to initialize a box.
    #
    # @param [String] name Logical name of the box.
    # @param [Symbol] provider The provider that this box implements.
    # @param [Pathname] directory The directory where this box exists on
    #   disk.
    def initialize(name, provider, version, directory, **opts)
      @name      = name
      @version   = version
      @provider  = provider
      @directory = directory
      @metadata_url = opts[:metadata_url]

      metadata_file = directory.join("metadata.json")
      raise Errors::BoxMetadataFileNotFound, :name => @name if !metadata_file.file?

      begin
        @metadata = JSON.parse(directory.join("metadata.json").read)
      rescue JSON::ParserError
        raise Errors::BoxMetadataCorrupted, name: @name
      end

      @logger = Log4r::Logger.new("vagrant::box")
    end

    # This deletes the box. This is NOT undoable.
    def destroy!
      # Delete the directory to delete the box.
      FileUtils.rm_r(@directory)

      # Just return true always
      true
    rescue Errno::ENOENT
      # This means the directory didn't exist. Not a problem.
      return true
    end

    # Loads the metadata URL and returns the latest metadata associated
    # with this box.
    #
    # @return [BoxMetadata]
    def load_metadata
      tf = Tempfile.new("vagrant")
      tf.close

      url = @metadata_url
      if File.file?(url) || url !~ /^[a-z0-9]+:.*$/i
        url = File.expand_path(url)
        url = Util::Platform.cygwin_windows_path(url)
        url = "file:#{url}"
      end

      Util::Downloader.new(url, tf.path).download!
      BoxMetadata.new(File.open(tf.path, "r"))
    end

    # Checks if the box has an update and returns the metadata, version,
    # and provider. If the box doesn't have an update that satisfies the
    # constraints, it will return nil.
    #
    # This will potentially make a network call if it has to load the
    # metadata from the network.
    #
    # @param [String] version Version constraints the update must
    #   satisfy. If nil, the version constrain defaults to being a
    #   larger version than this box.
    # @return [Array]
    def has_update?(version=nil)
      if !@metadata_url
        raise Errors::BoxUpdateNoMetadata, name: @name
      end

      version += ", " if version
      version ||= ""
      version += "> #{@version}"
      md      = self.load_metadata
      newer   = md.version(version, provider: @provider)
      return nil if !newer

      [md, newer, newer.provider(@provider)]
    end

    # This repackages this box and outputs it to the given path.
    #
    # @param [Pathname] path The full path (filename included) of where
    #   to output this box.
    # @return [Boolean] true if this succeeds.
    def repackage(path)
      @logger.debug("Repackaging box '#{@name}' to: #{path}")

      Util::SafeChdir.safe_chdir(@directory) do
        # Find all the files in our current directory and tar it up!
        files = Dir.glob(File.join(".", "**", "*"))

        # Package!
        Util::Subprocess.execute("bsdtar", "-czf", path.to_s, *files)
      end

      @logger.info("Repackaged box '#{@name}' successfully: #{path}")

      true
    end

    # Implemented for comparison with other boxes. Comparison is
    # implemented by comparing names and providers.
    def <=>(other)
      return super if !other.is_a?(self.class)

      # Comparison is done by composing the name and provider
      "#{@name}-#{@version}-#{@provider}" <=>
      "#{other.name}-#{other.version}-#{other.provider}"
    end
  end
end
