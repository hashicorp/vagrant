require "digest/sha1"
require "tmpdir"

require "archive/tar/minitar"
require "log4r"

module Vagrant
  # Represents a collection a boxes found on disk. This provides methods
  # for accessing/finding individual boxes, adding new boxes, or deleting
  # boxes.
  class BoxCollection
    # The directory where the boxes in this collection are stored.
    #
    # @return [Pathname]
    attr_reader :directory

    # Initializes the collection.
    #
    # @param [Pathname] directory The directory that contains the collection
    #   of boxes.
    def initialize(directory)
      @directory = directory
      @logger    = Log4r::Logger.new("vagrant::box_collection")
    end

    # This adds a new box to the system.
    #
    # There are some exceptional cases:
    # * BoxAlreadyExists - The box you're attempting to add already exists.
    # * BoxProviderDoesntMatch - If the given box provider doesn't match the
    #   actual box provider in the untarred box.
    # * BoxUnpackageFailure - An invalid tar file.
    # * BoxUpgradeRequired - You're attempting to add a box when there is a
    #   V1 box with the same name that must first be upgraded.
    #
    # Preconditions:
    # * File given in `path` must exist.
    #
    # @param [Pathname] path Path to the box file on disk.
    # @param [String] name Logical name for the box.
    # @param [Symbol] provider The provider that the box should be for. This
    #   will be verified with the `metadata.json` file in the box and is
    #   meant as a basic check. If this isn't given, then whatever provider
    #   the box represents will be added.
    def add(path, name, provider=nil)
      # A helper to check if a box exists. We store this in a variable
      # since we call it multiple times.
      check_box_exists = lambda do |box_provider|
        if find(name, box_provider)
          @logger.error("Box already exists, can't add: #{name} #{box_provider}")
          raise Errors::BoxAlreadyExists, :name => name, :provider => box_provider
        end
      end

      log_provider = provider ? provider : "any provider"
      @logger.debug("Adding box: #{name} (#{log_provider}) from #{path}")

      # Verify the box doesn't exist early if we're given a provider. This
      # can potentially speed things up considerably since we don't need
      # to unpack any files.
      check_box_exists.call(provider) if provider

      # Verify that a V1 box doesn't exist. If it does, then we signal
      # to the user that we need an upgrade.
      raise Errors::BoxUpgradeRequired, :name => name if v1_box?(@directory.join(name))

      # Create a temporary directory since we're not sure at this point if
      # the box we're unpackaging already exists (if no provider was given)
      Dir.mktmpdir("vagrant-") do |temp_dir|
        temp_dir = Pathname.new(temp_dir)

        # Extract the box into a temporary directory.
        @logger.debug("Unpacking box into temporary directory: #{temp_dir}")
        begin
          Archive::Tar::Minitar.unpack(path.to_s, temp_dir.to_s)
        rescue SystemCallError
          raise Errors::BoxUnpackageFailure
        end

        # If we get a V1 box, we want to update it in place
        if v1_box?(temp_dir)
          @logger.debug("Added box is a V1 box. Upgrading in place.")
          temp_dir = v1_upgrade(temp_dir)
        end

        # Get an instance of the box we just added before it is finalized
        # in the system so we can inspect and use its metadata.
        box = Box.new(name, provider, temp_dir)

        # Get the provider, since we'll need that to at the least add it
        # to the system or check that it matches what is given to us.
        box_provider = box.metadata["provider"]

        if provider
          # Verify that the given provider matches what the box has.
          if box_provider.to_sym != provider
            @logger.error("Added box provider doesnt match expected: #{box_provider}")
            raise Errors::BoxProviderDoesntMatch, :expected => provider, :actual => box_provider
          end
        else
          # We weren't given a provider, so store this one.
          provider = box_provider.to_sym

          # Verify the box doesn't already exist
          check_box_exists.call(provider)
        end

        # Create the directory that'll store our box
        final_dir = @directory.join(name, provider.to_s)
        @logger.debug("Final box directory: #{final_dir}")
        final_dir.mkpath

        # Move to the final destination
        File.rename(temp_dir, final_dir.to_s)

        # Recreate the directory. This avoids a bug in Ruby where `mktmpdir`
        # cleanup doesn't check if the directory is already gone. Ruby bug
        # #6715: http://bugs.ruby-lang.org/issues/6715
        Dir.mkdir(temp_dir, 0700)
      end

      # Return the box
      find(name, provider)
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
        return Box.new(name, provider, box_directory.dirname)
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
      if v1_box?(@directory.join(name))
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
      @logger.debug("Upgrade request for box: #{name}")
      box_dir = @directory.join(name)

      # If the box doesn't exist at all, raise an exception
      raise Errors::BoxNotFound, :name => name if !box_dir.directory?

      if v1_box?(box_dir)
        @logger.debug("V1 box #{name} found. Upgrading!")

        # First we actually perform the upgrade
        temp_dir = v1_upgrade(box_dir)

        # Rename the temporary directory to the provider.
        temp_dir.rename(box_dir.join("virtualbox"))
        @logger.info("Box '#{name}' upgraded from V1 to V2.")
      end

      # We did it! Or the v1 box didn't exist so it doesn't matter.
      return true
    end

    protected

    # This checks if the given directory represents a V1 box on the
    # system.
    #
    # @param [Pathname] dir Directory where the box is unpacked.
    # @return [Boolean]
    def v1_box?(dir)
      # We detect a V1 box given by whether there is a "box.ovf" which
      # is a heuristic but is pretty accurate.
      dir.join("box.ovf").file?
    end

    # This upgrades the V1 box contained unpacked in the given directory
    # and returns the directory of the upgraded version. This is
    # _destructive_ to the contents of the old directory. That is, the
    # contents of the old V1 box will be destroyed or moved.
    #
    # Preconditions:
    # * `dir` is a valid V1 box. Verify with {#v1_box?}
    #
    # @param [Pathname] dir Directory where the V1 box is unpacked.
    # @return [Pathname] Path to the unpackaged V2 box.
    def v1_upgrade(dir)
      @logger.debug("Upgrading box in directory: #{dir}")

      temp_dir = Pathname.new(Dir.mktmpdir("vagrant-"))
      @logger.debug("Temporary directory for upgrading: #{temp_dir}")

      # Move all the things into the temporary directory
      dir.children(true).each do |child|
        # Don't move the temp_dir
        next if child == temp_dir

        # Move every other directory into the temporary directory
        @logger.debug("Copying to upgrade directory: #{child}")
        FileUtils.mv(child, temp_dir.join(child.basename))
      end

      # If there is no metadata.json file, make one, since this is how
      # we determine if the box is a V2 box.
      metadata_file = temp_dir.join("metadata.json")
      if !metadata_file.file?
        metadata_file.open("w") do |f|
          f.write(JSON.generate({
            :provider => "virtualbox"
          }))
        end
      end

      # Return the temporary directory
      temp_dir
    end
  end
end
