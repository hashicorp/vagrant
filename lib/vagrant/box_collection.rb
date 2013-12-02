require "digest/sha1"
require "thread"
require "tmpdir"

require "log4r"

require "vagrant/util/subprocess"

module Vagrant
  # Represents a collection a boxes found on disk. This provides methods
  # for accessing/finding individual boxes, adding new boxes, or deleting
  # boxes.
  class BoxCollection
    TEMP_PREFIX = "vagrant-box-add-temp-"

    # The directory where the boxes in this collection are stored.
    #
    # A box collection matches a very specific folder structure that Vagrant
    # expects in order to easily manage and modify boxes. The folder structure
    # is the following:
    #
    #     COLLECTION_ROOT/BOX_NAME/PROVIDER/metadata.json
    #
    # Where:
    #
    #   * COLLECTION_ROOT - This is the root of the box collection, and is
    #     the directory given to the initializer.
    #   * BOX_NAME - The name of the box. This is a logical name given by
    #     the user of Vagrant.
    #   * PROVIDER - The provider that the box was built for (VirtualBox,
    #     VMWare, etc.).
    #   * metadata.json - A simple JSON file that at the bare minimum
    #     contains a "provider" key that matches the provider for the
    #     box. This metadata JSON, however, can contain anything.
    #
    # @return [Pathname]
    attr_reader :directory

    # Initializes the collection.
    #
    # @param [Pathname] directory The directory that contains the collection
    #   of boxes.
    def initialize(directory, options=nil)
      options ||= {}

      @directory = directory
      @lock      = Mutex.new
      @temp_root = options[:temp_dir_root]
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
    # @param [Boolean] force If true, any existing box with the same name
    #   and provider will be replaced.
    def add(path, name, formats=nil, force=false)
      formats = [formats] if formats && !formats.is_a?(Array)
      provider = nil

      with_collection_lock do
        # A helper to check if a box exists. We store this in a variable
        # since we call it multiple times.
        check_box_exists = lambda do |box_formats|
          box = find(name, box_formats)
          next if !box

          if !force
            @logger.error("Box already exists, can't add: #{name} #{box_formats.join(", ")}")
            raise Errors::BoxAlreadyExists, :name => name, :formats => box_formats.join(", ")
          end

          # We're forcing, so just delete the old box
          @logger.info(
            "Box already exists, but forcing so removing: #{name} #{box_formats.join(", ")}")
          box.destroy!
        end

        log_provider = formats ? formats.join(", ") : "any provider"
        @logger.debug("Adding box: #{name} (#{log_provider}) from #{path}")

        # Verify the box doesn't exist early if we're given a provider. This
        # can potentially speed things up considerably since we don't need
        # to unpack any files.
        check_box_exists.call(formats) if formats

        # Verify that a V1 box doesn't exist. If it does, then we signal
        # to the user that we need an upgrade.
        raise Errors::BoxUpgradeRequired, :name => name if v1_box?(@directory.join(name))

        # Create a temporary directory since we're not sure at this point if
        # the box we're unpackaging already exists (if no provider was given)
        with_temp_dir do |temp_dir|
          # Extract the box into a temporary directory.
          @logger.debug("Unpacking box into temporary directory: #{temp_dir}")
          result = Util::Subprocess.execute(
            "bsdtar", "-v", "-x", "-m", "-C", temp_dir.to_s, "-f", path.to_s)
          raise Errors::BoxUnpackageFailure, :output => result.stderr.to_s if result.exit_code != 0

          # If we get a V1 box, we want to update it in place
          if v1_box?(temp_dir)
            @logger.debug("Added box is a V1 box. Upgrading in place.")
            temp_dir = v1_upgrade(temp_dir)
          end

          # We re-wrap ourselves in the safety net in case we upgraded.
          # If we didn't upgrade, then this is still safe because the
          # helper will only delete the directory if it exists
          with_temp_dir(temp_dir) do |final_temp_dir|
            # Get an instance of the box we just added before it is finalized
            # in the system so we can inspect and use its metadata.
            box = Box.new(name, nil, final_temp_dir)

            # Get the provider, since we'll need that to at the least add it
            # to the system or check that it matches what is given to us.
            box_provider = box.metadata["provider"]

            if formats
              found = false
              formats.each do |format|
                # Verify that the given provider matches what the box has.
                if box_provider.to_sym == format.to_sym
                  found = true
                  break
                end
              end

              if !found
                @logger.error("Added box provider doesnt match expected: #{log_provider}")
                raise Errors::BoxProviderDoesntMatch,
                  :expected => log_provider, :actual => box_provider
              end
            else
              # Verify the box doesn't already exist
              check_box_exists.call([box_provider])
            end

            # We weren't given a provider, so store this one.
            provider = box_provider.to_sym

            # Create the directory for this box, not including the provider
            box_dir = @directory.join(name)
            box_dir.mkpath
            @logger.debug("Box directory: #{box_dir}")

            # This is the final directory we'll move it to
            final_dir = box_dir.join(provider.to_s)
            if final_dir.exist?
              @logger.debug("Removing existing provider directory...")
              final_dir.rmtree
            end

            # Move to final destination
            final_dir.mkpath

            # Go through each child and copy them one-by-one. This avoids
            # an issue where on Windows cross-device directory copies are
            # failing for some reason. [GH-1424]
            final_temp_dir.children(true).each do |f|
              destination = final_dir.join(f.basename)
              @logger.debug("Moving: #{f} => #{destination}")
              FileUtils.mv(f, destination)
            end
          end
        end
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

      with_collection_lock do
        @logger.debug("Finding all boxes in: #{@directory}")
        @directory.children(true).each do |child|
          # Ignore non-directories, since files are not interesting to
          # us in our folder structure.
          next if !child.directory?

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
      end

      results
    end

    # Find a box in the collection with the given name and provider.
    #
    # @param [String] name Name of the box (logical name).
    # @param [String] provider Provider that the box implements.
    # @return [Box] The box found, or `nil` if not found.
    def find(name, providers)
      providers = [providers].flatten

      with_collection_lock do
        providers.each do |provider|
          # First look directly for the box we're asking for.
          box_directory = @directory.join(name, provider.to_s, "metadata.json")
          @logger.info("Searching for box: #{name} (#{provider}) in #{box_directory}")
          if box_directory.file?
            @logger.info("Box found: #{name} (#{provider})")
            return Box.new(name, provider, box_directory.dirname)
          end

          # If we're looking for a VirtualBox box, then we check if there is
          # a V1 box.
          if provider.to_sym == :virtualbox
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
          end
        end
      end

      # Didn't find it, return nil
      @logger.info("Box not found: #{name} (#{providers.join(", ")})")
      nil
    end

    # Upgrades a V1 box with the given name to a V2 box. If a box with the
    # given name doesn't exist, then a `BoxNotFound` exception will be raised.
    # If the given box is found but is not a V1 box then `true` is returned
    # because this just works fine.
    #
    # @param [String] name Name of the box (logical name).
    # @return [Boolean] `true` otherwise an exception is raised.
    def upgrade(name)
      with_collection_lock do
        @logger.debug("Upgrade request for box: #{name}")
        box_dir = @directory.join(name)

        # If the box doesn't exist at all, raise an exception
        raise Errors::BoxNotFound, :name => name, :provider => "virtualbox" if !box_dir.directory?

        if v1_box?(box_dir)
          @logger.debug("V1 box #{name} found. Upgrading!")

          # First we actually perform the upgrade
          temp_dir = v1_upgrade(box_dir)

          # Rename the temporary directory to the provider.
          FileUtils.mv(temp_dir.to_s, box_dir.join("virtualbox").to_s)
          @logger.info("Box '#{name}' upgraded from V1 to V2.")
        end
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

      temp_dir = Pathname.new(Dir.mktmpdir(TEMP_PREFIX, @temp_root))
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

    # This locks the region given by the block with a lock on this
    # collection.
    def with_collection_lock
      lock = @lock

      begin
        lock.synchronize {}
      rescue ThreadError
        # If we already hold the lock, just create a new lock so
        # we definitely don't block and don't get an error.
        lock = Mutex.new
      end

      lock.synchronize do
        return yield
      end
    end

    # This is a helper that makes sure that our temporary directories
    # are cleaned up no matter what.
    #
    # @param [String] dir Path to a temporary directory
    # @return [Object] The result of whatever the yield is
    def with_temp_dir(dir=nil)
      dir ||= Dir.mktmpdir(TEMP_PREFIX, @temp_root)
      dir = Pathname.new(dir)

      yield dir
    ensure
      dir.rmtree if dir.exist?
    end
  end
end
