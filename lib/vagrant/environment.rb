require 'pathname'
require 'fileutils'

require 'log4r'

require 'vagrant/util/file_mode'

module Vagrant
  # Represents a single Vagrant environment. A "Vagrant environment" is
  # defined as basically a folder with a "Vagrantfile." This class allows
  # access to the VMs, CLI, etc. all in the scope of this environment.
  class Environment
    HOME_SUBDIRS = ["tmp", "boxes"]
    DEFAULT_VM = :default
    DEFAULT_HOME = "~/.vagrant.d"

    # The `cwd` that this environment represents
    attr_reader :cwd

    # The valid name for a Vagrantfile for this environment.
    attr_reader :vagrantfile_name

    # The {UI} object to communicate with the outside world.
    attr_reader :ui

    # The directory to the "home" folder that Vagrant will use to store
    # global state.
    attr_reader :home_path

    # The directory where temporary files for Vagrant go.
    attr_reader :tmp_path

    # The directory where boxes are stored.
    attr_reader :boxes_path

    # The path to the default private key
    attr_reader :default_private_key_path

    #---------------------------------------------------------------
    # Class Methods
    #---------------------------------------------------------------
    class << self
      # Verifies that VirtualBox is installed and that the version of
      # VirtualBox installed is high enough.
      def check_virtualbox!
        version = VirtualBox.version
        raise Errors::VirtualBoxNotDetected if version.nil?
        raise Errors::VirtualBoxInvalidVersion, :version => version.to_s if version.to_f < 4.1 || version.to_f >= 4.2
      rescue Errors::VirtualBoxNotDetected
        # On 64-bit Windows, show a special error. This error is a subclass
        # of VirtualBoxNotDetected, so libraries which use Vagrant can just
        # rescue VirtualBoxNotDetected.
        raise Errors::VirtualBoxNotDetected_Win64 if Util::Platform.windows? && Util::Platform.bit64?

        # Otherwise, reraise the old error
        raise
      end
    end

    # Initializes a new environment with the given options. The options
    # is a hash where the main available key is `cwd`, which defines where
    # the environment represents. There are other options available but
    # they shouldn't be used in general. If `cwd` is nil, then it defaults
    # to the `Dir.pwd` (which is the cwd of the executing process).
    def initialize(opts=nil)
      opts = {
        :cwd => nil,
        :vagrantfile_name => nil,
        :lock_path => nil,
        :ui_class => nil,
        :home_path => nil
      }.merge(opts || {})

      # Set the default working directory to look for the vagrantfile
      opts[:cwd] ||= Dir.pwd
      opts[:cwd] = Pathname.new(opts[:cwd])

      # Set the default vagrantfile name, which can be either Vagrantfile
      # or vagrantfile (capital for backwards compatibility)
      opts[:vagrantfile_name] ||= ["Vagrantfile", "vagrantfile"]
      opts[:vagrantfile_name] = [opts[:vagrantfile_name]] if !opts[:vagrantfile_name].is_a?(Array)

      # Set instance variables for all the configuration parameters.
      @cwd    = opts[:cwd]
      @vagrantfile_name = opts[:vagrantfile_name]
      @lock_path = opts[:lock_path]
      @home_path = opts[:home_path]

      ui_class = opts[:ui_class] || UI::Silent
      @ui      = ui_class.new("vagrant")

      @loaded = false
      @lock_acquired = false

      @logger = Log4r::Logger.new("vagrant::environment")
      @logger.info("Environment initialized (#{self})")
      @logger.info("  - cwd: #{cwd}")

      # Setup the home directory
      setup_home_path
      @tmp_path = @home_path.join("tmp")
      @boxes_path = @home_path.join("boxes")

      # Setup the default private key
      @default_private_key_path = @home_path.join("insecure_private_key")
      copy_insecure_private_key
    end

    #---------------------------------------------------------------
    # Helpers
    #---------------------------------------------------------------

    # The path to the `dotfile`, which contains the persisted UUID of
    # the VM if it exists.
    #
    # @return [Pathname]
    def dotfile_path
      return nil if !root_path
      root_path.join(config.global.vagrant.dotfile_name)
    end

    # Returns the collection of boxes for the environment.
    #
    # @return [BoxCollection]
    def boxes
      @_boxes ||= BoxCollection.new(boxes_path, action_runner)
    end

    # Returns the VMs associated with this environment.
    #
    # @return [Hash<Symbol,VM>]
    def vms
      load! if !loaded?
      @vms ||= load_vms!
    end

    # Returns the VMs associated with this environment, in the order
    # that they were defined.
    #
    # @return [Array<VM>]
    def vms_ordered
      return @vms.values if !multivm?
      @vms_enum ||= config.global.vm.defined_vm_keys.map { |name| @vms[name] }
    end

    # Returns the primary VM associated with this environment. This
    # method is only applicable for multi-VM environments. This can
    # potentially be nil if no primary VM is specified.
    #
    # @return [VM]
    def primary_vm
      return vms.values.first if !multivm?

      config.vm.defined_vms.each do |name, subvm|
        return vms[name] if subvm.options[:primary]
      end

      nil
    end

    # Returns a boolean whether this environment represents a multi-VM
    # environment or not. This will work even when called on child
    # environments.
    #
    # @return [Bool]
    def multivm?
      vms.length > 1 || vms.keys.first != DEFAULT_VM
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
    # @return [Hosts::Base]
    def host
      return @host if defined?(@host)

      # Attempt to figure out the host class. Note that the order
      # matters here, so please don't touch. Specifically: The symbol
      # check is done after the detect check because the symbol check
      # will return nil, and we don't want to trigger a detect load.
      host_klass = config.global.vagrant.host
      host_klass = Hosts.detect(Vagrant.hosts) if host_klass.nil? || host_klass == :detect
      host_klass = Vagrant.hosts.get(host_klass) if host_klass.is_a?(Symbol)
      @host ||= host_klass.new(@ui)
    end

    # Action runner for executing actions in the context of this environment.
    #
    # @return [Action::Runner]
    def action_runner
      @action_runner ||= Action::Runner.new(action_registry) do |env|
        {
          :action_runner  => action_runner,
          :box_collection => boxes,
          :global_config  => config.global,
          :host           => host,
          :root_path      => root_path,
          :tmp_path       => tmp_path,
          :ui             => @ui
        }
      end
    end

    # Action registry for registering new actions with this environment.
    #
    # @return [Registry]
    def action_registry
      return @action_registry if defined?(@action_registry)

      # The action registry hasn't been loaded yet, so load it
      # and setup the built-in actions with it.
      @action_registry = Registry.new
      Vagrant::Action.builtin!(@action_registry)
      @action_registry
    end

    # Loads on initial access and reads data from the global data store.
    # The global data store is global to Vagrant everywhere (in every environment),
    # so it can be used to store system-wide information. Note that "system-wide"
    # typically means "for this user" since the location of the global data
    # store is in the home directory.
    #
    # @return [DataStore]
    def global_data
      @global_data ||= DataStore.new(File.expand_path("global_data.json", home_path))
    end

    # Loads (on initial access) and reads data from the local data
    # store. This file is always at the root path as the file "~/.vagrant"
    # and contains a JSON dump of a hash. See {DataStore} for more
    # information.
    #
    # @return [DataStore]
    def local_data
      @local_data ||= DataStore.new(dotfile_path)
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
        found = vagrantfile_name.find do |rootfile|
          File.exist?(File.join(path.to_s, rootfile))
        end

        return path if found
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
    # Config Methods
    #---------------------------------------------------------------

    # The configuration object represented by this environment. This
    # will trigger the environment to load if it hasn't loaded yet (see
    # {#load!}).
    #
    # @return [Config::Container]
    def config
      load! if !loaded?
      @config
    end

    #---------------------------------------------------------------
    # Load Methods
    #---------------------------------------------------------------

    # Returns a boolean representing if the environment has been
    # loaded or not.
    #
    # @return [Bool]
    def loaded?
      !!@loaded
    end

    # Loads this entire environment, setting up the instance variables
    # such as `vm`, `config`, etc. on this environment. The order this
    # method calls its other methods is very particular.
    def load!
      if !loaded?
        @loaded = true

        @logger.info("Environment not loaded. Checking virtual box version...")
        self.class.check_virtualbox!

        @logger.info("Loading configuration...")
        load_config!
      end

      self
    end

    # Reloads the configuration of this environment.
    def reload!
      # Reload the configuration
      load_config!

      # Clear the VMs because this can now be diferent due to configuration
      @vms = nil
    end

    # Loads this environment's configuration and stores it in the {#config}
    # variable. The configuration loaded by this method is specified to
    # this environment, meaning that it will use the given root directory
    # to load the Vagrantfile into that context.
    def load_config!
      # Initialize the config loader
      config_loader = Config::Loader.new
      config_loader.load_order = [:default, :box, :home, :root, :vm]

      inner_load = lambda do |*args|
        # This is for Ruby 1.8.7 compatibility. Ruby 1.8.7 doesn't allow
        # default arguments for lambdas, so we get around by doing a *args
        # and setting the args here.
        subvm = args[0]
        box   = args[1]

        # Default Vagrantfile first. This is the Vagrantfile that ships
        # with Vagrant.
        config_loader.set(:default, File.expand_path("config/default.rb", Vagrant.source_root))

        vagrantfile_name.each do |rootfile|
          if box
            # We load the box Vagrantfile
            box_vagrantfile = box.directory.join(rootfile)
            config_loader.set(:box, box_vagrantfile) if box_vagrantfile.exist?
          end

          if home_path
            # Load the home Vagrantfile
            home_vagrantfile = home_path.join(rootfile)
            config_loader.set(:home, home_vagrantfile) if home_vagrantfile.exist?
          end

          if root_path
            # Load the Vagrantfile in this directory
            root_vagrantfile = root_path.join(rootfile)
            config_loader.set(:root, root_vagrantfile) if root_vagrantfile.exist?
          end
        end

        if subvm
          # We have subvm configuration, so set that up as well.
          config_loader.set(:vm, subvm.proc_stack)
        end

        # Execute the configuration stack and store the result as the final
        # value in the config ivar.
        config_loader.load
      end

      # For the global configuration, we only need to load the configuration
      # in a single pass, since nothing is conditional on the configuration.
      global = inner_load.call

      # For each virtual machine represented by this environment, we have
      # to load the configuration in two-passes. We do this because the
      # first pass is used to determine the box for the VM. The second pass
      # is used to also load the box Vagrantfile.
      defined_vm_keys = global.vm.defined_vm_keys.dup
      defined_vms     = global.vm.defined_vms.dup

      # If this isn't a multi-VM environment, then setup the default VM
      # to simply be our configuration.
      if defined_vm_keys.empty?
        defined_vm_keys << DEFAULT_VM
        defined_vms[DEFAULT_VM] = Config::VMConfig::SubVM.new
      end

      vm_configs = defined_vm_keys.map do |vm_name|
        @logger.debug("Loading configuration for VM: #{vm_name}")

        subvm = defined_vms[vm_name]

        # First pass, first run.
        config = inner_load[subvm]

        # Second pass, with the box
        config = inner_load[subvm, boxes.find(config.vm.box)]
        config.vm.name = vm_name

        # Return the final configuration for this VM
        config
      end

      # Finally, we have our configuration. Set it and forget it.
      @config = Config::Container.new(global, vm_configs)
    end

    # Loads the persisted VM (if it exists) for this environment.
    def load_vms!
      result = {}

      # Load the VM UUIDs from the local data store
      (local_data[:active] || {}).each do |name, uuid|
        vm = VirtualBox::VM.find(uuid)
        result[name.to_sym] = Vagrant::VM.new(name.to_sym,
                                              self,
                                              config.for_vm(name.to_sym),
                                              vm)
      end

      # For any VMs which aren't created, create a blank VM instance for them.
      config.vms.each do |name|
        if !result.has_key?(name)
          result[name] = Vagrant::VM.new(name, self, config.for_vm(name))
        end
      end

      result
    end

    # This sets the `@home_path` variable properly.
    #
    # @return [Pathname]
    def setup_home_path
      @home_path = Pathname.new(File.expand_path(@home_path ||
                                                 ENV["VAGRANT_HOME"] ||
                                                 DEFAULT_HOME))
      @logger.info("Home path: #{@home_path}")

      # Setup the array of necessary home directories
      dirs = [@home_path]
      dirs += HOME_SUBDIRS.collect { |subdir| @home_path.join(subdir) }

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
        FileUtils.cp(File.expand_path("keys/vagrant", Vagrant.source_root),
                     @default_private_key_path)
      end

      if Util::FileMode.from_octal(@default_private_key_path.stat.mode) != "600"
        @logger.info("Changing permissions on private key to 0600")
        @default_private_key_path.chmod(0600)
      end
    end
  end
end
