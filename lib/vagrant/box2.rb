require "json"

module Vagrant
  # Represents a "box," which is a package Vagrant environment that is used
  # as a base image when creating a new guest machine.
  #
  # XXX: This will be renamed to "Box" when it is more stable and functional,
  # and the old Box will be removed.
  class Box2
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
      @metadata  = JSON.parse(directory.join("metadata.json").read)
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

    # Implemented for comparison with other boxes. Comparison is
    # implemented by comparing names and providers.
    def <=>(other)
      return super if !other.is_a?(self.class)

      # Comparison is done by composing the name and provider
      "#{@name}-#{@provider}" <=> "#{other.name}-#{other.provider}"
    end
  end
end
