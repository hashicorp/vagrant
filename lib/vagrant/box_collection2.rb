require "digest/sha1"

require "log4r"

module Vagrant
  # Represents a collection a boxes found on disk. This provides methods
  # for accessing/finding individual boxes, adding new boxes, or deleting
  # boxes.
  #
  # XXX: This will be renamed to "BoxCollection" when it is more stable
  # and functional, and the old BoxCollection will be removed.
  class BoxCollection2
    # Initializes the collection.
    #
    # @param [Pathname] directory The directory that contains the collection
    #   of boxes.
    def initialize(directory)
      @directory = directory
      @logger    = Log4r::Logger.new("vagrant::box_collection")
    end

    # This returns an array of all the boxes on the system, given by
    # their name and their provider.
    #
    # @return [Array] Array of `[name, provider]` pairs of the boxes
    #   installed on this system. An optional third element in the array
    #   may specify `:v1` if the box is a version 1 box.
    def all
      results = []

      @logger.debug("Finding all boxes in: #{@directory}")
      @directory.children(true).each do |child|
        box_name = child.basename.to_s

        # If this is a V1 box, we still return that name, but specify
        # that the box is a V1 box.
        if v1_box?(child)
          @logger.debug("V1 box found: #{box_name}")
          results << [box_name, :virtualbox, :v1]
          next
        end

        # Otherwise, traverse the subdirectories and see what providers
        # we have.
        child.children(true).each do |provider|
          # Verify this is a potentially valid box. If it looks
          # correct enough then include it.
          if provider.directory? && provider.join("metadata.json").file?
            provider_name = provider.basename.to_s.to_sym
            @logger.debug("Box: #{box_name} (#{provider_name})")
            results << [box_name, provider_name]
          else
            @logger.debug("Invalid box, ignoring: #{provider}")
          end
        end
      end

      results
    end

    # Find a box in the collection with the given name and provider.
    #
    # @param [String] name Name of the box (logical name).
    # @Param [String] provider Provider that the box implements.
    # @return [Box] The box found, or `nil` if not found.
    def find(name, provider)
      # First look directly for the box we're asking for.
      box_directory = @directory.join(name, provider.to_s, "metadata.json")
      @logger.info("Searching for box: #{name} (#{provider}) in #{box_directory}")
      if box_directory.file?
        @logger.debug("Box found: #{name} (#{provider})")
        return Box2.new(name, provider, box_directory.dirname)
      end

      # Check if a V1 version of this box exists, and if so, raise an
      # exception notifying the caller that the box exists but needs
      # to be upgraded. We don't do the upgrade here because it can be
      # a fairly intensive activity and don't want to immediately degrade
      # user performance on a find.
      #
      # To determine if it is a V1 box we just do a simple heuristic
      # based approach.
      @logger.info("Searching for V1 box: #{name}")
      if v1_box?(name)
        @logger.warn("V1 box found: #{name}")
        raise Errors::BoxUpgradeRequired, :name => name
      end

      # Didn't find it, return nil
      @logger.info("Box not found: #{name} (#{provider})")
      nil
    end

    # Upgrades a V1 box with the given name to a V2 box. If a box with the
    # given name doesn't exist, then a `BoxNotFound` exception will be raised.
    # If the given box is found but is not a V1 box then `true` is returned
    # because this just works fine.
    #
    # @return [Boolean] `true` otherwise an exception is raised.
    def upgrade(name)
      box_dir = @directory.join(name)

      # If the box doesn't exist at all, raise an exception
      raise Errors::BoxNotFound, :name => name if !box_dir.directory?

      if v1_box?(name)
        # First, we create a temporary directory within the box to store
        # the intermediary moved files. We randomize this in case there is
        # already a directory named "virtualbox" in here for some reason.
        temp_dir = box_dir.join("vagrant-#{Digest::SHA1.hexdigest(name)}")

        # Make the temporary directory
        temp_dir.mkpath

        # Move all the things into the temporary directory
        box_dir.children(true).each do |child|
          # Don't move the temp_dir
          next if child == temp_dir

          # Move every other directory into the temporary directory
          FileUtils.mv(child, temp_dir.join(child.basename))
        end

        # If there is no metadata.json file, make one, since this is how
        # we determine if the box is a V2 box.
        metadata_file = temp_dir.join("metadata.json")
        if !metadata_file.file?
          metadata_file.open("w") do |f|
            f.write(JSON.generate({}))
          end
        end

        # Rename the temporary directory to the provider.
        temp_dir.rename(box_dir.join("virtualbox"))
      end

      # We did it! Or the v1 box didn't exist so it doesn't matter.
      return true
    end

    protected

    # This checks if the given name represents a V1 box on the system.
    #
    # @return [Boolean]
    def v1_box?(name)
      # We detect a V1 box given by whether there is a "box.ovf" which
      # is a heuristic but is pretty accurate.
      @directory.join(name, "box.ovf").file?
    end
  end
end
