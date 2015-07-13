require "digest/sha1"
require "monitor"
require "tmpdir"

require "log4r"

require "vagrant/util/platform"
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
    #     VMware, etc.).
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
      @hook      = options[:hook]
      @lock      = Monitor.new
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
    #
    # Preconditions:
    # * File given in `path` must exist.
    #
    # @param [Pathname] path Path to the box file on disk.
    # @param [String] name Logical name for the box.
    # @param [String] version The version of this box.
    # @param [Array<String>] providers The providers that this box can
    #   be a part of. This will be verified with the `metadata.json` and is
    #   meant as a basic check. If this isn't given, then whatever provider
    #   the box represents will be added.
    # @param [Boolean] force If true, any existing box with the same name
    #   and provider will be replaced.
    def add(path, name, version, **opts)
      providers = opts[:providers]
      providers = Array(providers) if providers
      provider = nil

      # A helper to check if a box exists. We store this in a variable
      # since we call it multiple times.
      check_box_exists = lambda do |box_formats|
        box = find(name, box_formats, version)
        next if !box

        if !opts[:force]
          @logger.error(
            "Box already exists, can't add: #{name} v#{version} #{box_formats.join(", ")}")
          raise Errors::BoxAlreadyExists,
            name: name,
            provider: box_formats.join(", "),
            version: version
        end

        # We're forcing, so just delete the old box
        @logger.info(
          "Box already exists, but forcing so removing: " +
          "#{name} v#{version} #{box_formats.join(", ")}")
        box.destroy!
      end

      with_collection_lock do
        log_provider = providers ? providers.join(", ") : "any provider"
        @logger.debug("Adding box: #{name} (#{log_provider}) from #{path}")

        # Verify the box doesn't exist early if we're given a provider. This
        # can potentially speed things up considerably since we don't need
        # to unpack any files.
        check_box_exists.call(providers) if providers

        # Create a temporary directory since we're not sure at this point if
        # the box we're unpackaging already exists (if no provider was given)
        with_temp_dir do |temp_dir|
          # Extract the box into a temporary directory.
          @logger.debug("Unpacking box into temporary directory: #{temp_dir}")
          result = Util::Subprocess.execute(
            "bsdtar", "-v", "-x", "-m", "-C", temp_dir.to_s, "-f", path.to_s)
          if result.exit_code != 0
            raise Errors::BoxUnpackageFailure,
              output: result.stderr.to_s
          end

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
            box = Box.new(name, nil, version, final_temp_dir)

            # Get the provider, since we'll need that to at the least add it
            # to the system or check that it matches what is given to us.
            box_provider = box.metadata["provider"]

            if providers
              found = providers.find { |p| p.to_sym == box_provider.to_sym }
              if !found
                @logger.error("Added box provider doesnt match expected: #{log_provider}")
                raise Errors::BoxProviderDoesntMatch,
                  expected: log_provider, actual: box_provider
              end
            else
              # Verify the box doesn't already exist
              check_box_exists.call([box_provider])
            end

            # We weren't given a provider, so store this one.
            provider = box_provider.to_sym

            # Create the directory for this box, not including the provider
            root_box_dir = @directory.join(dir_name(name))
            box_dir = root_box_dir.join(version)
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

            # Recursively move individual files from the temporary directory
            # to the final location. We do this instead of moving the entire
            # directory to avoid issues on Windows. [GH-1424]
            copy_pairs = [[final_temp_dir, final_dir]]
            while !copy_pairs.empty?
              from, to = copy_pairs.shift
              from.children(true).each do |f|
                dest = to.join(f.basename)

                # We don't copy entire directories, so create the
                # directory and then add to our list to copy.
                if f.directory?
                  dest.mkpath
                  copy_pairs << [f, dest]
                  next
                end

                # Copy the single file
                @logger.debug("Moving: #{f} => #{dest}")
                FileUtils.mv(f, dest)
              end
            end

            if opts[:metadata_url]
              root_box_dir.join("metadata_url").open("w") do |f|
                f.write(opts[:metadata_url])
              end
            end
          end
        end
      end

      # Return the box
      find(name, provider, version)
    end

    # This returns an array of all the boxes on the system, given by
    # their name and their provider.
    #
    # @return [Array] Array of `[name, version, provider]` of the boxes
    #   installed on this system.
    def all
      results = []

      with_collection_lock do
        @logger.debug("Finding all boxes in: #{@directory}")
        @directory.children(true).each do |child|
          # Ignore non-directories, since files are not interesting to
          # us in our folder structure.
          next if !child.directory?

          box_name = undir_name(child.basename.to_s)

          # Otherwise, traverse the subdirectories and see what versions
          # we have.
          child.children(true).each do |versiondir|
            next if !versiondir.directory?
            next if versiondir.basename.to_s.start_with?(".")

            version = versiondir.basename.to_s

            versiondir.children(true).each do |provider|
              # Verify this is a potentially valid box. If it looks
              # correct enough then include it.
              if provider.directory? && provider.join("metadata.json").file?
                provider_name = provider.basename.to_s.to_sym
                @logger.debug("Box: #{box_name} (#{provider_name})")
                results << [box_name, version, provider_name]
              else
                @logger.debug("Invalid box, ignoring: #{provider}")
              end
            end
          end
        end
      end

      results
    end

    # Find a box in the collection with the given name and provider.
    #
    # @param [String] name Name of the box (logical name).
    # @param [Array] providers Providers that the box implements.
    # @param [String] version Version constraints to adhere to. Example:
    #   "~> 1.0" or "= 1.0, ~> 1.1"
    # @return [Box] The box found, or `nil` if not found.
    def find(name, providers, version)
      providers = Array(providers)

      # Build up the requirements we have
      requirements = version.to_s.split(",").map do |v|
        Gem::Requirement.new(v.strip)
      end

      with_collection_lock do
        box_directory = @directory.join(dir_name(name))
        if !box_directory.directory?
          @logger.info("Box not found: #{name} (#{providers.join(", ")})")
          return nil
        end

        versions = box_directory.children(true).map do |versiondir|
          next if !versiondir.directory?
          next if versiondir.basename.to_s.start_with?(".")

          version = versiondir.basename.to_s
          Gem::Version.new(version)
        end.compact

        # Traverse through versions with the latest version first
        versions.sort.reverse.each do |v|
          if !requirements.all? { |r| r.satisfied_by?(v) }
            # Unsatisfied version requirements
            next
          end

          versiondir = box_directory.join(v.to_s)
          providers.each do |provider|
            provider_dir = versiondir.join(provider.to_s)
            next if !provider_dir.directory?
            @logger.info("Box found: #{name} (#{provider})")

            metadata_url = nil
            metadata_url_file = box_directory.join("metadata_url")
            metadata_url = metadata_url_file.read if metadata_url_file.file?

            if metadata_url && @hook
              hook_env     = @hook.call(
                :authenticate_box_url, box_urls: [metadata_url])
              metadata_url = hook_env[:box_urls].first
            end

            return Box.new(
              name, provider, v.to_s, provider_dir,
              metadata_url: metadata_url,
            )
          end
        end
      end

      nil
    end

    # This upgrades a v1.1 - v1.4 box directory structure up to a v1.5
    # directory structure. This will raise exceptions if it fails in any
    # way.
    def upgrade_v1_1_v1_5
      with_collection_lock do
        temp_dir = Pathname.new(Dir.mktmpdir(TEMP_PREFIX, @temp_root))

        @directory.children(true).each do |boxdir|
          # Ignore all non-directories because they can't be boxes
          next if !boxdir.directory?

          box_name = boxdir.basename.to_s

          # If it is a v1 box, then we need to upgrade it first
          if v1_box?(boxdir)
            upgrade_dir = v1_upgrade(boxdir)
            FileUtils.mv(upgrade_dir, boxdir.join("virtualbox"))
          end

          # Create the directory for this box
          new_box_dir = temp_dir.join(dir_name(box_name), "0")
          new_box_dir.mkpath

          # Go through each provider and move it
          boxdir.children(true).each do |providerdir|
            FileUtils.cp_r(providerdir, new_box_dir.join(providerdir.basename))
          end
        end

        # Move the folder into place
        @directory.rmtree
        FileUtils.mv(temp_dir.to_s, @directory.to_s)
      end
    end

    protected

    # Returns the directory name for the box of the given name.
    #
    # @param [String] name
    # @return [String]
    def dir_name(name)
      name = name.dup
      name.gsub!(":", "-VAGRANTCOLON-") if Util::Platform.windows?
      name.gsub!("/", "-VAGRANTSLASH-")
      name
    end

    # Returns the directory name for the box cleaned up
    def undir_name(name)
      name = name.dup
      name.gsub!("-VAGRANTCOLON-", ":")
      name.gsub!("-VAGRANTSLASH-", "/")
      name
    end

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
            provider: "virtualbox"
          }))
        end
      end

      # Return the temporary directory
      temp_dir
    end

    # This locks the region given by the block with a lock on this
    # collection.
    def with_collection_lock
      @lock.synchronize do
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
