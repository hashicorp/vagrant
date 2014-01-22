require 'fileutils'
require 'json'
require 'pathname'
require 'set'
require 'thread'

require 'log4r'

require 'vagrant/util/file_mode'
require 'vagrant/util/platform'

module Vagrant
  # Represents a single Vagrant environment. A "Vagrant environment" is
  # defined as basically a folder with a "Vagrantfile." This class allows
  # access to the VMs, CLI, etc. all in the scope of this environment.
  class Environment
    # This is the current version that this version of Vagrant is
    # compatible with in the home directory.
    #
    # @return [String]
    CURRENT_SETUP_VERSION = "1.5"

    DEFAULT_LOCAL_DATA = ".vagrant"

    # The `cwd` that this environment represents
    attr_reader :cwd

    # The persistent data directory where global data can be stored. It
    # is up to the creator of the data in this directory to properly
    # remove it when it is no longer needed.
    #
    # @return [Pathname]
    attr_reader :data_dir

    # The valid name for a Vagrantfile for this environment.
    attr_reader :vagrantfile_name

    # The {UI} object to communicate with the outside world.
    attr_reader :ui

    # This is the UI class to use when creating new UIs.
    attr_reader :ui_class

    # The directory to the "home" folder that Vagrant will use to store
    # global state.
    attr_reader :home_path

    # The directory to the directory where local, environment-specific
    # data is stored.
    attr_reader :local_data_path

    # The directory where temporary files for Vagrant go.
    attr_reader :tmp_path

    # The directory where boxes are stored.
    attr_reader :boxes_path

    # The path where the plugins are stored (gems)
    attr_reader :gems_path

    # The path to the default private key
    attr_reader :default_private_key_path

    # Initializes a new environment with the given options. The options
    # is a hash where the main available key is `cwd`, which defines where
    # the environment represents. There are other options available but
    # they shouldn't be used in general. If `cwd` is nil, then it defaults
    # to the `Dir.pwd` (which is the cwd of the executing process).
    def initialize(opts=nil)
      opts = {
        :cwd              => nil,
        :home_path        => nil,
        :local_data_path  => nil,
        :lock_path        => nil,
        :ui_class         => nil,
        :vagrantfile_name => nil,
      }.merge(opts || {})

      # Set the default working directory to look for the vagrantfile
      opts[:cwd] ||= ENV["VAGRANT_CWD"] if ENV.has_key?("VAGRANT_CWD")
      opts[:cwd] ||= Dir.pwd
      opts[:cwd] = Pathname.new(opts[:cwd])
      if !opts[:cwd].directory?
        raise Errors::EnvironmentNonExistentCWD, cwd: opts[:cwd].to_s
      end

      # Set the default ui class
      opts[:ui_class] ||= UI::Silent

      # Set the Vagrantfile name up. We append "Vagrantfile" and "vagrantfile" so that
      # those continue to work as well, but anything custom will take precedence.
      opts[:vagrantfile_name] ||= ENV["VAGRANT_VAGRANTFILE"] if \
        ENV.has_key?("VAGRANT_VAGRANTFILE")
      opts[:vagrantfile_name] = [opts[:vagrantfile_name]] if \
        opts[:vagrantfile_name] && !opts[:vagrantfile_name].is_a?(Array)

      # Set instance variables for all the configuration parameters.
      @cwd              = opts[:cwd]
      @home_path        = opts[:home_path]
      @lock_path        = opts[:lock_path]
      @vagrantfile_name = opts[:vagrantfile_name]
      @ui               = opts[:ui_class].new
      @ui_class         = opts[:ui_class]

      # This is the batch lock, that enforces that only one {BatchAction}
      # runs at a time from {#batch}.
      @batch_lock = Mutex.new

      @lock_acquired = false

      @logger = Log4r::Logger.new("vagrant::environment")
      @logger.info("Environment initialized (#{self})")
      @logger.info("  - cwd: #{cwd}")

      # Setup the home directory
      setup_home_path
      @boxes_path = @home_path.join("boxes")
      @data_dir   = @home_path.join("data")
      @gems_path  = @home_path.join("gems")
      @tmp_path   = @home_path.join("tmp")

      # Setup the local data directory. If a configuration path is given,
      # then it is expanded relative to the working directory. Otherwise,
      # we use the default which is expanded relative to the root path.
      opts[:local_data_path] ||= ENV["VAGRANT_DOTFILE_PATH"]
      opts[:local_data_path] ||= root_path.join(DEFAULT_LOCAL_DATA) if !root_path.nil?
      if opts[:local_data_path]
        @local_data_path = Pathname.new(File.expand_path(opts[:local_data_path], @cwd))
      end

      setup_local_data_path

      # Setup the default private key
      @default_private_key_path = @home_path.join("insecure_private_key")
      copy_insecure_private_key

      # Call the hooks that does not require configurations to be loaded
      # by using a "clean" action runner
      hook(:environment_plugins_loaded, runner: Action::Runner.new(env: self))

      # Call the environment load hooks
      hook(:environment_load)
    end

    # Return a human-friendly string for pretty printed or inspected
    # instances.
    #
    # @return [String]
    def inspect
      "#<#{self.class}: #{@cwd}>"
    end

    #---------------------------------------------------------------
    # Helpers
    #---------------------------------------------------------------

    # Returns a list of machines that this environment is currently
    # managing that physically have been created.
    #
    # An "active" machine is a machine that Vagrant manages that has
    # been created. The machine itself may be in any state such as running,
    # suspended, etc. but if a machine is "active" then it exists.
    #
    # Note that the machines in this array may no longer be present in
    # the Vagrantfile of this environment. In this case the machine can
    # be considered an "orphan." Determining which machines are orphan
    # and which aren't is not currently a supported feature, but will
    # be in a future version.
    #
    # @return [Array<String, Symbol>]
    def active_machines
      machine_folder = @local_data_path.join("machines")

      # If the machine folder is not a directory then we just return
      # an empty array since no active machines exist.
      return [] if !machine_folder.directory?

      # Traverse the machines folder accumulate a result
      result = []

      machine_folder.children(true).each do |name_folder|
        # If this isn't a directory then it isn't a machine
        next if !name_folder.directory?

        name = name_folder.basename.to_s.to_sym
        name_folder.children(true).each do |provider_folder|
          # If this isn't a directory then it isn't a provider
          next if !provider_folder.directory?

          # If this machine doesn't have an ID, then ignore
          next if !provider_folder.join("id").file?

          provider = provider_folder.basename.to_s.to_sym
          result << [name, provider]
        end
      end

      # Return the results
      result
    end

    # This creates a new batch action, yielding it, and then running it
    # once the block is called.
    #
    # This handles the case where batch actions are disabled by the
    # VAGRANT_NO_PARALLEL environmental variable.
    def batch(parallel=true)
      parallel = false if ENV["VAGRANT_NO_PARALLEL"]

      @batch_lock.synchronize do
        BatchAction.new(parallel).tap do |b|
          # Yield it so that the caller can setup actions
          yield b

          # And run it!
          b.run
        end
      end
    end

    # This returns the provider name for the default provider for this
    # environment. The provider returned is currently hardcoded to "virtualbox"
    # but one day should be a detected valid, best-case provider for this
    # environment.
    #
    # @return [Symbol] Name of the default provider.
    def default_provider
      (ENV['VAGRANT_DEFAULT_PROVIDER'] || :virtualbox).to_sym
    end

    # Returns the collection of boxes for the environment.
    #
    # @return [BoxCollection]
    def boxes
      @_boxes ||= BoxCollection.new(boxes_path, temp_dir_root: tmp_path)
    end

    # This is the global config, comprised of loading configuration from
    # the default, home, and root Vagrantfiles. This configuration is only
    # really useful for reading the list of virtual machines, since each
    # individual VM can override _most_ settings.
    #
    # This is lazy-loaded upon first use.
    #
    # @return [Object]
    def config_global
      return @config_global if @config_global

      @logger.info("Initializing config...")

      home_vagrantfile = nil
      root_vagrantfile = nil
      home_vagrantfile = find_vagrantfile(home_path) if home_path
      root_vagrantfile = find_vagrantfile(root_path, @vagrantfile_name) if root_path

      # Create the configuration loader and set the sources that are global.
      # We use this to load the configuration, and the list of machines we are
      # managing. Then, the actual individual configuration is loaded for
      # each {#machine} call.
      @config_loader = Config::Loader.new(Config::VERSIONS, Config::VERSIONS_ORDER)
      @config_loader.set(:home, home_vagrantfile) if home_vagrantfile
      @config_loader.set(:root, root_vagrantfile) if root_vagrantfile

      # Make the initial call to get the "global" config. This is mostly
      # only useful to get the list of machines that we are managing.
      # Because of this, we ignore any warnings or errors.
      @config_global, _ = @config_loader.load([:home, :root])

      # Return the config
      @config_global
    end

    # This defines a hook point where plugin action hooks that are registered
    # against the given name will be run in the context of this environment.
    #
    # @param [Symbol] name Name of the hook.
    # @param [Action::Runner] action_runner A custom action runner for running hooks.
    def hook(name, opts=nil)
      @logger.info("Running hook: #{name}")
      opts ||= {}
      opts[:callable] ||= Action::Builder.new
      opts[:runner] ||= action_runner
      opts[:action_name] = name
      opts[:env] = self
      opts.delete(:runner).run(opts.delete(:callable), opts)
    end

    # This returns a machine with the proper provider for this environment.
    # The machine named by `name` must be in this environment.
    #
    # @param [Symbol] name Name of the machine (as configured in the
    #   Vagrantfile).
    # @param [Symbol] provider The provider that this machine should be
    #   backed by.
    # @param [Boolean] refresh If true, then if there is a cached version
    #   it is reloaded.
    # @return [Machine]
    def machine(name, provider, refresh=false)
      @logger.info("Getting machine: #{name} (#{provider})")

      # Compose the cache key of the name and provider, and return from
      # the cache if we have that.
      cache_key = [name, provider]
      @machines ||= {}
      if refresh
        @logger.info("Refreshing machine (busting cache): #{name} (#{provider})")
        @machines.delete(cache_key)
      end

      if @machines.has_key?(cache_key)
        @logger.info("Returning cached machine: #{name} (#{provider})")
        return @machines[cache_key]
      end

      @logger.info("Uncached load of machine.")
      sub_vm = config_global.vm.defined_vms[name]
      if !sub_vm
        raise Errors::MachineNotFound, :name => name, :provider => provider
      end

      provider_plugin  = Vagrant.plugin("2").manager.providers[provider]
      if !provider_plugin
        raise Errors::ProviderNotFound, :machine => name, :provider => provider
      end

      # Extra the provider class and options from the plugin data
      provider_cls     = provider_plugin[0]
      provider_options = provider_plugin[1]

      # Build the machine configuration. This requires two passes: The first pass
      # loads in the machine sub-configuration. Since this can potentially
      # define a new box to base the machine from, we then make a second pass
      # with the box Vagrantfile (if it has one).
      vm_config_key = "vm_#{name}".to_sym
      @config_loader.set(vm_config_key, sub_vm.config_procs)
      config, config_warnings, config_errors = \
        @config_loader.load([:home, :root, vm_config_key])

      # Determine the possible box formats for any boxes and find the box
      box_formats = provider_options[:box_format] || provider
      box = nil

      # Set this variable in order to keep track of if the box changes
      # too many times.
      original_box = config.vm.box
      box_changed  = false

      load_box_and_overrides = lambda do
        box = nil
        if config.vm.box
          begin
            box = boxes.find(config.vm.box, box_formats)
          rescue Errors::BoxUpgradeRequired
            # Upgrade the box if we must
            @logger.info("Upgrading box during config load: #{config.vm.box}")
            boxes.upgrade(config.vm.box)
            retry
          end
        end

        # If a box was found, then we attempt to load the Vagrantfile for
        # that box. We don't require a box since we allow providers to download
        # boxes and so on.
        if box
          box_vagrantfile = find_vagrantfile(box.directory)
          if box_vagrantfile
            # The box has a custom Vagrantfile, so we load that into the config
            # as well.
            @logger.info("Box exists with Vagrantfile. Reloading machine config.")
            box_config_key = "box_#{box.name}_#{box.provider}".to_sym
            @config_loader.set(box_config_key, box_vagrantfile)
            config, config_warnings, config_errors = \
              @config_loader.load([box_config_key, :home, :root, vm_config_key])
          end
        end

        # If there are provider overrides for the machine, then we run
        # those as well.
        provider_overrides = config.vm.get_provider_overrides(provider)
        if provider_overrides.length > 0
          @logger.info("Applying #{provider_overrides.length} provider overrides. Reloading config.")
          provider_override_key = "vm_#{name}_#{config.vm.box}_#{provider}".to_sym
          @config_loader.set(provider_override_key, provider_overrides)
          config, config_warnings, config_errors = \
            @config_loader.load([box_config_key, :home, :root, vm_config_key, provider_override_key])
        end

        if config.vm.box && original_box != config.vm.box
          if box_changed
            # We already changed boxes once, so report an error that a
            # box is attempting to change boxes again.
            raise Errors::BoxConfigChangingBox
          end

          # The box changed, probably due to the provider override. Let's
          # run the configuration one more time with the new box.
          @logger.info("Box changed to: #{config.vm.box}. Reloading configurations.")
          original_box = config.vm.box
          box_changed  = true

          # Recurse so that we reload all the configurations
          load_box_and_overrides.call
        end
      end

      # Load the box and overrides configuration
      load_box_and_overrides.call

      # Get the provider configuration from the final loaded configuration
      provider_config = config.vm.get_provider_config(provider)

      # Determine the machine data directory and pass it to the machine.
      # XXX: Permissions error here.
      machine_data_path = @local_data_path.join("machines/#{name}/#{provider}")
      FileUtils.mkdir_p(machine_data_path)

      # If there were warnings or errors we want to output them
      if !config_warnings.empty? || !config_errors.empty?
        # The color of the output depends on whether we have warnings
        # or errors...
        level  = config_errors.empty? ? :warn : :error
        output = Util::TemplateRenderer.render(
          "config/messages",
          :warnings => config_warnings,
          :errors => config_errors).chomp
        @ui.send(level, I18n.t("vagrant.general.config_upgrade_messages",
                               name: name,
                               :output => output))

          # If we had errors, then we bail
          raise Errors::ConfigUpgradeErrors if !config_errors.empty?
      end

      # Create the machine and cache it for future calls. This will also
      # return the machine from this method.
      @machines[cache_key] = Machine.new(name, provider, provider_cls, provider_config,
                                         provider_options, config, machine_data_path, box, self)
    end

    # This returns a list of the configured machines for this environment.
    # Each of the names returned by this method is valid to be used with
    # the {#machine} method.
    #
    # @return [Array<Symbol>] Configured machine names.
    def machine_names
      config_global.vm.defined_vm_keys.dup
    end

    # This returns the name of the machine that is the "primary." In the
    # case of  a single-machine environment, this is just the single machine
    # name. In the case of a multi-machine environment, then this can
    # potentially be nil if no primary machine is specified.
    #
    # @return [Symbol]
    def primary_machine_name
      # If it is a single machine environment, then return the name
      return machine_names.first if machine_names.length == 1

      # If it is a multi-machine environment, then return the primary
      config_global.vm.defined_vms.each do |name, subvm|
        return name if subvm.options[:primary]
      end

      # If no primary was specified, nil it is
      nil
    end

    # Unload the environment, running completion hooks. The environment
    # should not be used after this (but CAN be, technically). It is
    # recommended to always immediately set the variable to `nil` after
    # running this so you can't accidentally run any more methods. Example:
    #
    #     env.unload
    #     env = nil
    #
    def unload
      hook(:environment_unload)
    end

    # Makes a call to the CLI with the given arguments as if they
    # came from the real command line (sometimes they do!). An example:
    #
    #     env.cli("package", "--vagrantfile", "Vagrantfile")
    #
    def cli(*args)
      CLI.new(args.flatten, self).execute
    end

    # Returns the host object associated with this environment.
    #
    # @return [Class]
    def host
      return @host if defined?(@host)

      # Determine the host class to use. ":detect" is an old Vagrant config
      # that shouldn't be valid anymore, but we respect it here by assuming
      # its old behavior. No need to deprecate this because I thin it is
      # fairly harmless.
      host_klass = config_global.vagrant.host
      host_klass = nil if host_klass == :detect

      begin
        @host = Host.new(
          host_klass,
          Vagrant.plugin("2").manager.hosts,
          Vagrant.plugin("2").manager.host_capabilities,
          self)
      rescue Errors::CapabilityHostNotDetected
        # If the auto-detect failed, then we create a brand new host
        # with no capabilities and use that. This should almost never happen
        # since Vagrant works on most host OS's now, so this is a "slow path"
        klass = Class.new(Vagrant.plugin("2", :host)) do
          def detect?(env); true; end
        end

        hosts     = { generic: [klass, nil] }
        host_caps = {}

        @host = Host.new(:generic, hosts, host_caps, self)
      rescue Errors::CapabilityHostExplicitNotDetected => e
        raise Errors::HostExplicitNotDetected, e.extra_data
      end
    end

    # Action runner for executing actions in the context of this environment.
    #
    # @return [Action::Runner]
    def action_runner
      @action_runner ||= Action::Runner.new do
        {
          :action_runner  => action_runner,
          :box_collection => boxes,
          :global_config  => config_global,
          :hook           => method(:hook),
          :host           => host,
          :gems_path      => gems_path,
          :home_path      => home_path,
          :root_path      => root_path,
          :tmp_path       => tmp_path,
          :ui             => @ui
        }
      end
    end

    # The root path is the path where the top-most (loaded last)
    # Vagrantfile resides. It can be considered the project root for
    # this environment.
    #
    # @return [String]
    def root_path
      return @root_path if defined?(@root_path)

      root_finder = lambda do |path|
        # Note: To remain compatible with Ruby 1.8, we have to use
        # a `find` here instead of an `each`.
        vf = find_vagrantfile(path, @vagrantfile_name)
        return path if vf
        return nil if path.root? || !File.exist?(path)
        root_finder.call(path.parent)
      end

      @root_path = root_finder.call(cwd)
    end

    # This returns the path which Vagrant uses to determine the location
    # of the file lock. This is specific to each operating system.
    def lock_path
      @lock_path || tmp_path.join("vagrant.lock")
    end

    # This locks Vagrant for the duration of the block passed to this
    # method. During this time, any other environment which attempts
    # to lock which points to the same lock file will fail.
    def lock
      # This allows multiple locks in the same process to be nested
      return yield if @lock_acquired

      File.open(lock_path, "w+") do |f|
        # The file locking fails only if it returns "false." If it
        # succeeds it returns a 0, so we must explicitly check for
        # the proper error case.
        raise Errors::EnvironmentLockedError if f.flock(File::LOCK_EX | File::LOCK_NB) === false

        begin
          # Mark that we have a lock
          @lock_acquired = true

          yield
        ensure
          # We need to make sure that no matter what this is always
          # reset to false so we don't think we have a lock when we
          # actually don't.
          @lock_acquired = false
        end
      end
    end

    #---------------------------------------------------------------
    # Load Methods
    #---------------------------------------------------------------

    # This sets the `@home_path` variable properly.
    #
    # @return [Pathname]
    def setup_home_path
      @home_path = Util::Platform.fs_real_path(
        @home_path || Vagrant.user_data_path)
      @logger.info("Home path: #{@home_path}")

      # Setup the list of child directories that need to be created if they
      # don't already exist.
      dirs    = [@home_path]
      subdirs = ["boxes", "data", "gems", "rgloader", "tmp"]
      dirs    += subdirs.collect { |subdir| @home_path.join(subdir) }

      # Go through each required directory, creating it if it doesn't exist
      dirs.each do |dir|
        next if File.directory?(dir)

        begin
          @logger.info("Creating: #{dir}")
          FileUtils.mkdir_p(dir)
        rescue Errno::EACCES
          raise Errors::HomeDirectoryNotAccessible, :home_path => @home_path.to_s
        end
      end

      # Attempt to write into the home directory to verify we can
      begin
        path = @home_path.join("perm_test")
        path.open("w") do |f|
          f.write("hello")
        end
        path.unlink
      rescue Errno::EACCES
        raise Errors::HomeDirectoryNotAccessible, home_path: @home_path.to_s
      end

      # Create the version file that we use to track the structure of
      # the home directory. If we have an old version, we need to explicitly
      # upgrade it. Otherwise, we just mark that its the current version.
      version_file = @home_path.join("setup_version")
      if version_file.file?
        version = version_file.read
        case version
        when CURRENT_SETUP_VERSION
          # We're already good, at the latest version.
        when "1.1"
          # We need to update our directory structure
          upgrade_home_path_v1_1

          # Delete the version file so we put our latest version in
          version_file.delete
        else
          raise Errors::HomeDirectoryUnknownVersion,
            path: @home_path.to_s,
            version: version
        end
      end

      if !version_file.file?
        @logger.debug(
          "Creating home directory version file: #{CURRENT_SETUP_VERSION}")
        version_file.open("w") do |f|
          f.write(CURRENT_SETUP_VERSION)
        end
      end

      # Create the rgloader/loader file so we can use encoded files.
      loader_file = @home_path.join("rgloader", "loader.rb")
      if !loader_file.file?
        source_loader = Vagrant.source_root.join("templates/rgloader.rb")
        FileUtils.cp(source_loader.to_s, loader_file.to_s)
      end
    end

    # This creates the local data directory and show an error if it
    # couldn't properly be created.
    def setup_local_data_path
      if @local_data_path.nil?
        @logger.warn("No local data path is set. Local data cannot be stored.")
        return
      end

      @logger.info("Local data path: #{@local_data_path}")

      # If the local data path is a file, then we are probably seeing an
      # old (V1) "dotfile." In this case, we upgrade it. The upgrade process
      # will remove the old data file if it is successful.
      if @local_data_path.file?
        upgrade_v1_dotfile(@local_data_path)
      end

      begin
        @logger.debug("Creating: #{@local_data_path}")
        FileUtils.mkdir_p(@local_data_path)
      rescue Errno::EACCES
        raise Errors::LocalDataDirectoryNotAccessible,
          :local_data_path => @local_data_path.to_s
      end
    end

    protected

    # This method copies the private key into the home directory if it
    # doesn't already exist.
    #
    # This must be done because `ssh` requires that the key is chmod
    # 0600, but if Vagrant is installed as a separate user, then the
    # effective uid won't be able to read the key. So the key is copied
    # to the home directory and chmod 0600.
    def copy_insecure_private_key
      if !@default_private_key_path.exist?
        @logger.info("Copying private key to home directory")

        source      = File.expand_path("keys/vagrant", Vagrant.source_root)
        destination = @default_private_key_path

        begin
          FileUtils.cp(source, destination)
        rescue Errno::EACCES
          raise Errors::CopyPrivateKeyFailed,
            :source => source,
            :destination => destination
        end
      end

      if !Util::Platform.windows?
        # On Windows, permissions don't matter as much, so don't worry
        # about doing chmod.
        if Util::FileMode.from_octal(@default_private_key_path.stat.mode) != "600"
          @logger.info("Changing permissions on private key to 0600")
          @default_private_key_path.chmod(0600)
        end
      end
    end

    # Finds the Vagrantfile in the given directory.
    #
    # @param [Pathname] path Path to search in.
    # @return [Pathname]
    def find_vagrantfile(search_path, filenames=nil)
      filenames ||= ["Vagrantfile", "vagrantfile"]
      filenames.each do |vagrantfile|
        current_path = search_path.join(vagrantfile)
        return current_path if current_path.file?
      end

      nil
    end

    # This upgrades a home directory that was in the v1.1 format to the
    # v1.5 format. It will raise exceptions if anything fails.
    def upgrade_home_path_v1_1
      collection = BoxCollection.new(
        @home_path.join("boxes"), temp_dir_root: tmp_path)
      collection.upgrade_v1_1_v1_5
    end

    # This upgrades a Vagrant 1.0.x "dotfile" to the new V2 format.
    #
    # This is a destructive process. Once the upgrade is complete, the
    # old dotfile is removed, and the environment becomes incompatible for
    # Vagrant 1.0 environments.
    #
    # @param [Pathname] path The path to the dotfile
    def upgrade_v1_dotfile(path)
      @logger.info("Upgrading V1 dotfile to V2 directory structure...")

      # First, verify the file isn't empty. If it is an empty file, we
      # just delete it and go on with life.
      contents = path.read.strip
      if contents.strip == ""
        @logger.info("V1 dotfile was empty. Removing and moving on.")
        path.delete
        return
      end

      # Otherwise, verify there is valid JSON in here since a Vagrant
      # environment would always ensure valid JSON. This is a sanity check
      # to make sure we don't nuke a dotfile that is not ours...
      @logger.debug("Attempting to parse JSON of V1 file")
      json_data = nil
      begin
        json_data = JSON.parse(contents)
        @logger.debug("JSON parsed successfully. Things are okay.")
      rescue JSON::ParserError
        # The file could've been tampered with since Vagrant 1.0.x is
        # supposed to ensure that the contents are valid JSON. Show an error.
        raise Errors::DotfileUpgradeJSONError,
          :state_file => path.to_s
      end

      # Alright, let's upgrade this guy to the new structure. Start by
      # backing up the old dotfile.
      backup_file = path.dirname.join(".vagrant.v1.#{Time.now.to_i}")
      @logger.info("Renaming old dotfile to: #{backup_file}")
      path.rename(backup_file)

      # Now, we create the actual local data directory. This should succeed
      # this time since we renamed the old conflicting V1.
      setup_local_data_path

      if json_data["active"]
        @logger.debug("Upgrading to V2 style for each active VM")
        json_data["active"].each do |name, id|
          @logger.info("Upgrading dotfile: #{name} (#{id})")

          # Create the machine configuration directory
          directory = @local_data_path.join("machines/#{name}/virtualbox")
          FileUtils.mkdir_p(directory)

          # Write the ID file
          directory.join("id").open("w+") do |f|
            f.write(id)
          end
        end
      end

      # Upgrade complete! Let the user know
      @ui.info(I18n.t("vagrant.general.upgraded_v1_dotfile",
                      :backup_path => backup_file.to_s))
    end
  end
end
