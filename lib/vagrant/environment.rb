require 'pathname'
require 'fileutils'

require 'log4r'

module Vagrant
  # Represents a single Vagrant environment. A "Vagrant environment" is
  # defined as basically a folder with a "Vagrantfile." This class allows
  # access to the VMs, CLI, etc. all in the scope of this environment.
  class Environment
    HOME_SUBDIRS = ["tmp", "boxes", "logs"]
    DEFAULT_VM = :default
    DEFAULT_HOME = "~/.vagrant.d"

    # Parent environment (in the case of multi-VMs)
    attr_reader :parent

    # The `cwd` that this environment represents
    attr_reader :cwd

    # The valid name for a Vagrantfile for this environment.
    attr_reader :vagrantfile_name

    # The single VM that this environment represents, in the case of
    # multi-VM.
    attr_accessor :vm

    # The {UI} object to communicate with the outside world.
    attr_writer :ui

    # The {Config} object representing the Vagrantfile loader
    attr_reader :config_loader

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
        :parent => nil,
        :vm => nil,
        :cwd => nil,
        :vagrantfile_name => nil,
        :lock_path => nil,
        :ui_class => nil
      }.merge(opts || {})

      # Set the default working directory to look for the vagrantfile
      opts[:cwd] ||= Dir.pwd
      opts[:cwd] = Pathname.new(opts[:cwd])

      # Set the default vagrantfile name, which can be either Vagrantfile
      # or vagrantfile (capital for backwards compatibility)
      opts[:vagrantfile_name] ||= ["Vagrantfile", "vagrantfile"]
      opts[:vagrantfile_name] = [opts[:vagrantfile_name]] if !opts[:vagrantfile_name].is_a?(Array)

      # Set instance variables for all the configuration parameters.
      @parent = opts[:parent]
      @vm     = opts[:vm]
      @cwd    = opts[:cwd]
      @vagrantfile_name = opts[:vagrantfile_name]
      @lock_path = opts[:lock_path]
      @ui_class  = opts[:ui_class]

      @loaded = false
      @lock_acquired = false

      @logger = Log4r::Logger.new("vagrant::environment")
      @logger.info("Environment initialized (#{self})")
      @logger.info("  - cwd: #{cwd}")
      @logger.info("  - parent: #{parent}")
      @logger.info("  - vm: #{vm}")
    end

    #---------------------------------------------------------------
    # Helpers
    #---------------------------------------------------------------

    # The path to the `dotfile`, which contains the persisted UUID of
    # the VM if it exists.
    #
    # @return [Pathname]
    def dotfile_path
      root_path.join(config.vagrant.dotfile_name) rescue nil
    end

    # The path to the home directory and converted into a Pathname object.
    #
    # @return [Pathname]
    def home_path
      return parent.home_path if parent
      return @_home_path if defined?(@_home_path)

      @_home_path ||= Pathname.new(File.expand_path(ENV["VAGRANT_HOME"] || DEFAULT_HOME))
      @logger.info("Home path: #{@_home_path}")
      @_home_path
    end

    # The path to the Vagrant tmp directory
    #
    # @return [Pathname]
    def tmp_path
      home_path.join("tmp")
    end

    # The path to the Vagrant boxes directory
    #
    # @return [Pathname]
    def boxes_path
      home_path.join("boxes")
    end

    # Path to the Vagrant logs directory
    #
    # @return [Pathname]
    def log_path
      home_path.join("logs")
    end

    # Returns the name of the resource which this environment represents.
    # The resource is the VM name if there is a VM it represents, otherwise
    # it defaults to "vagrant"
    #
    # @return [String]
    def resource
      result = vm.name rescue nil
      result || "vagrant"
    end

    # Returns the collection of boxes for the environment.
    #
    # @return [BoxCollection]
    def boxes
      return parent.boxes if parent
      @_boxes ||= BoxCollection.new(self)
    end

    # Returns the box that this environment represents.
    #
    # @return [Box]
    def box
      boxes.find(config.vm.box)
    end

    # Returns the VMs associated with this environment.
    #
    # @return [Hash<Symbol,VM>]
    def vms
      return parent.vms if parent
      load! if !loaded?
      @vms ||= load_vms!
    end

    # Returns the VMs associated with this environment, in the order
    # that they were defined.
    #
    # @return [Array<VM>]
    def vms_ordered
      @vms_enum ||= config.vm.defined_vm_keys.map { |name| @vms[name] }
    end

    # Returns the primary VM associated with this environment. This
    # method is only applicable for multi-VM environments. This can
    # potentially be nil if no primary VM is specified.
    #
    # @return [VM]
    def primary_vm
      return vms.values.first if !multivm?
      return parent.primary_vm if parent

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
      if parent
        parent.multivm?
      else
        vms.length > 1 || vms.keys.first != DEFAULT_VM
      end
    end

    # Makes a call to the CLI with the given arguments as if they
    # came from the real command line (sometimes they do!). An example:
    #
    #     env.cli("package", "--vagrantfile", "Vagrantfile")
    #
    def cli(*args)
      CLI.start(args.flatten, :env => self)
    end

    # Returns the {UI} for the environment, which is responsible
    # for talking with the outside world.
    #
    # @return [UI]
    def ui
      @ui ||= if parent
        result = parent.ui.clone
        result.env = self
        result
      else
        ui_class = @ui_class || UI::Silent
        ui_class.new(self)
      end
    end

    # Returns the host object associated with this environment.
    #
    # @return [Hosts::Base]
    def host
      @host ||= Hosts::Base.load(self, config.vagrant.host)
    end

    # Returns the {Action} class for this environment which allows actions
    # to be executed (middleware chains) in the context of this environment.
    #
    # @return [Action]
    def actions
      @actions ||= Action.new(self)
    end

    # Loads on initial access and reads data from the global data store.
    # The global data store is global to Vagrant everywhere (in every environment),
    # so it can be used to store system-wide information. Note that "system-wide"
    # typically means "for this user" since the location of the global data
    # store is in the home directory.
    #
    # @return [DataStore]
    def global_data
      return parent.global_data if parent
      @global_data ||= DataStore.new(File.expand_path("global_data.json", home_path))
    end

    # Loads (on initial access) and reads data from the local data
    # store. This file is always at the root path as the file "~/.vagrant"
    # and contains a JSON dump of a hash. See {DataStore} for more
    # information.
    #
    # @return [DataStore]
    def local_data
      return parent.local_data if parent
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
    # @return [Config::Top]
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

        if !parent
          # We only need to check the virtualbox version once, so do it on
          # the parent most environment and then forget about it
          @logger.info("Environment not loaded. Checking virtual box version...")
          self.class.check_virtualbox!
        end

        @logger.info("Loading configuration...")
        load_config!
      end

      self
    end

    # Reloads the configuration of this environment.
    def reload_config!
      @config = nil
      @config_loader = nil
      load_config!
      self
    end

    # Loads this environment's configuration and stores it in the {#config}
    # variable. The configuration loaded by this method is specified to
    # this environment, meaning that it will use the given root directory
    # to load the Vagrantfile into that context.
    def load_config!
      first_run = @config.nil?

      # First load the initial, non config-dependent Vagrantfiles
      @config_loader ||= Config.new(parent ? parent.config_loader : nil)
      @config_loader.load_order = [:default, :box, :home, :root, :sub_vm]
      @config_loader.set(:default, File.expand_path("config/default.rb", Vagrant.source_root))

      vagrantfile_name.each do |rootfile|
        if !first_run && vm && box
          # We load the box Vagrantfile
          box_vagrantfile = box.directory.join(rootfile)
          @config_loader.set(:box, box_vagrantfile) if box_vagrantfile.exist?
        end

        if !first_run && home_path
          # Load the home Vagrantfile
          home_vagrantfile = home_path.join(rootfile)
          @config_loader.set(:home, home_vagrantfile) if home_vagrantfile.exist?
        end

        if root_path
          # Load the Vagrantfile in this directory
          root_vagrantfile = root_path.join(rootfile)
          @config_loader.set(:root, root_vagrantfile) if root_vagrantfile.exist?
        end
      end

      # If this environment is representing a sub-VM, then we push that
      # proc on as the last configuration.
      if vm
        subvm = parent.config.vm.defined_vms[vm.name]
        @config_loader.set(:sub_vm, subvm.proc_stack) if subvm
      end

      # Execute the configuration stack and store the result as the final
      # value in the config ivar.
      @config = @config_loader.load(self)

      if first_run
        # After the first run we want to load the configuration again since
        # it can change due to box Vagrantfiles and home directory Vagrantfiles
        load_home_directory!
        load_config!
      end
    end

    # Loads the home directory path and creates the necessary subdirectories
    # within the home directory if they're not already created.
    def load_home_directory!
      # Setup the array of necessary home directories
      dirs = [home_path]
      dirs += HOME_SUBDIRS.collect { |subdir| home_path.join(subdir) }

      # Go through each required directory, creating it if it doesn't exist
      dirs.each do |dir|
        next if File.directory?(dir)

        ui.info I18n.t("vagrant.general.creating_home_dir", :directory => dir)
        FileUtils.mkdir_p(dir)
      end
    end

    # Loads the persisted VM (if it exists) for this environment.
    def load_vms!
      result = {}

      # Load the VM UUIDs from the local data store
      (local_data[:active] || {}).each do |name, uuid|
        result[name.to_sym] = Vagrant::VM.find(uuid, self, name.to_sym)
      end

      # For any VMs which aren't created, create a blank VM instance for
      # them
      all_keys = config.vm.defined_vm_keys
      all_keys = [DEFAULT_VM] if all_keys.empty?
      all_keys.each do |name|
        result[name] = Vagrant::VM.new(:name => name, :env => self) if !result.has_key?(name)
      end

      result
    end
  end
end
