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
    end

    # Find a box in the collection with the given name and provider.
    #
    # @param [String] name Name of the box (logical name).
    # @Param [String] provider Provider that the box implements.
    # @return [Box] The box found, or `nil` if not found.
    def find(name, provider)
      # First look directly for the box we're asking for.
      box_directory = @directory.join(name, provider.to_s, "metadata.json")
      return Box2.new(name, provider, box_directory.dirname) if box_directory.file?

      # Check if a V1 version of this box exists, and if so, raise an
      # exception notifying the caller that the box exists but needs
      # to be upgraded. We don't do the upgrade here because it can be
      # a fairly intensive activity and don't want to immediately degrade
      # user performance on a find.
      #
      # To determine if it is a V1 box we just do a simple heuristic
      # based approach.
      if @directory.join(name, "box.ovf").file?
        raise Errors::BoxUpgradeRequired, :name => name
      end

      # Didn't find it, return nil
      nil
    end
  end
end
