require 'fileutils'

require "json"
require "log4r"

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

    # This is the directory on disk where this box exists.
    #
    # @return [Pathname]
    attr_reader :directory

    # This is the metadata for the box. This is read from the "metadata.json"
    # file that all boxes require.
    #
    # @return [Hash]
    attr_reader :metadata

    # This is used to initialize a box.
    #
    # @param [String] name Logical name of the box.
    # @param [Symbol] provider The provider that this box implements.
    # @param [Pathname] directory The directory where this box exists on
    #   disk.
    def initialize(name, provider, directory)
      @name      = name
      @provider  = provider
      @directory = directory

      metadata_file = directory.join("metadata.json")
      raise Errors::BoxMetadataFileNotFound, :name => @name if !metadata_file.file?
      @metadata = JSON.parse(directory.join("metadata.json").read)

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
      "#{@name}-#{@provider}" <=> "#{other.name}-#{other.provider}"
    end
  end
end
