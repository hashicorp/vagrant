require 'pathname'
require 'fileutils'

module Vagrant
  # Represents a single Vagrant environment. This class is responsible
  # for loading all of the Vagrantfile's for the given environment and
  # storing references to the various instances.
  class Environment
    ROOTFILE_NAME = "Vagrantfile"
    HOME_SUBDIRS = ["tmp", "boxes", "logs"]
    DEFAULT_VM = :default

    attr_reader :parent     # Parent environment (in the case of multi-VMs)

    attr_reader :cwd
    attr_accessor :vm
    attr_writer :ui

    #---------------------------------------------------------------
    # Class Methods
    #---------------------------------------------------------------
    class << self
      # Verifies that VirtualBox is installed and that the version of
      # VirtualBox installed is high enough.
      def check_virtualbox!
        version = VirtualBox.version
        raise Errors::VirtualBoxNotDetected.new if version.nil?
        raise Errors::VirtualBoxInvalidVersion.new(:version => version.to_s) if version.to_f < 3.2
        raise Errors::VirtualBoxInvalidOSE.new(:version => version.to_s) if version.to_s.downcase.include?("ose")
      end
    end

    def initialize(opts=nil)
      opts = {
        :parent => nil,
        :vm => nil,
        :cwd => nil,
      }.merge(opts || {})

      opts[:cwd] ||= Dir.pwd
      opts[:cwd] = Pathname.new(opts[:cwd])

      opts.each do |key, value|
        instance_variable_set("@#{key}".to_sym, opts[key])
      end

      @loaded = false
    end

    #---------------------------------------------------------------
    # Helpers
    #---------------------------------------------------------------

    # The path to the `dotfile`, which contains the persisted UUID of
    # the VM if it exists.
    def dotfile_path
      root_path.join(config.vagrant.dotfile_name) rescue nil
    end

    # The path to the home directory, expanded relative to the root path,
    # and converted into a Pathname object.
    def home_path
      @_home_path ||= Pathname.new(File.expand_path(config.vagrant.home, root_path))
    end

    # The path to the Vagrant tmp directory
    def tmp_path
      home_path.join("tmp")
    end

    # The path to the Vagrant boxes directory
    def boxes_path
      home_path.join("boxes")
    end

    # Path to the Vagrant logs directory
    def log_path
      home_path.join("logs")
    end

    # Returns the name of the resource which this environment represents.
    # The resource is the VM name if there is a VM it represents, otherwise
    # it defaults to "vagrant"
    def resource
      vm.name rescue "vagrant"
    end

    # Returns the collection of boxes for the environment.
    def boxes
      return parent.boxes if parent
      @_boxes ||= BoxCollection.new(self)
    end

    # Returns the box that this environment represents.
    def box
      boxes.find(config.vm.box)
    end

    # Returns the VMs associated with this environment.
    def vms
      return parent.vms if parent
      load! if !loaded?
      @vms ||= load_vms!
    end

    # Returns the primray VM associated with this environment
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
    def multivm?
      if parent
        parent.multivm?
      else
        vms.length > 1
      end
    end

    # Makes a call to the CLI with the given arguments as if they
    # came from the real command line (sometimes they do!)
    def cli(*args)
      CLI.start(args.flatten, :env => self)
    end

    # Returns the {UI} for the environment, which is responsible
    # for talking with the outside world.
    def ui
      @ui ||= if parent
        result = parent.ui.clone
        result.env = self
        result
      else
        UI.new(self)
      end
    end

    # Returns the host object associated with this environment.
    def host
      @host ||= Hosts::Base.load(self, config.vagrant.host)
    end

    # Returns the {Action} class for this environment which allows actions
    # to be executed (middleware chains) in the context of this environment.
    def actions
      @actions ||= Action.new(self)
    end

    # Loads on initial access and reads data from the global data store.
    # The global data store is global to Vagrant everywhere (in every environment),
    # so it can be used to store system-wide information. Note that "system-wide"
    # typically means "for this user" since the location of the global data
    # store is in the home directory.
    def global_data
      return parent.global_data if parent
      @global_data ||= DataStore.new(File.expand_path("global_data.json", home_path))
    end

    # Loads (on initial access) and reads data from the local data
    # store. This file is always at the root path as the file "~/.vagrant"
    # and contains a JSON dump of a hash. See {DataStore} for more
    # information.
    def local_data
      return parent.local_data if parent
      @local_data ||= DataStore.new(dotfile_path)
    end

    # Accesses the logger for Vagrant. This logger is a _detailed_
    # logger which should be used to log internals only. For outward
    # facing information, use {#ui}.
    def logger
      return parent.logger if parent
      @logger ||= Util::ResourceLogger.new(resource, self)
    end

    # The root path is the path where the top-most (loaded last)
    # Vagrantfile resides. It can be considered the project root for
    # this environment.
    def root_path
      return @root_path if defined?(@root_path)

      root_finder = lambda do |path|
        return path if File.exist?(File.join(path.to_s, ROOTFILE_NAME))
        return nil if path.root?
        root_finder.call(path.parent)
      end

      @root_path = root_finder.call(cwd)
    end

    #---------------------------------------------------------------
    # Config Methods
    #---------------------------------------------------------------

    # The configuration object represented by this environment. This
    # will trigger the environment to load if it hasn't loaded yet (see
    # {#load!}).
    def config
      load! if !loaded?
      @config
    end

    #---------------------------------------------------------------
    # Load Methods
    #---------------------------------------------------------------

    # Returns a boolean representing if the environment has been
    # loaded or not.
    def loaded?
      !!@loaded
    end

    # Loads this entire environment, setting up the instance variables
    # such as `vm`, `config`, etc. on this environment. The order this
    # method calls its other methods is very particular.
    def load!
      if !loaded?
        @loaded = true
        self.class.check_virtualbox!
        load_config!
        actions.run(:environment_load)
      end

      self
    end

    # Loads this environment's configuration and stores it in the {config}
    # variable. The configuration loaded by this method is specified to
    # this environment, meaning that it will use the given root directory
    # to load the Vagrantfile into that context.
    def load_config!
      first_run = @config.nil?

      # First load the initial, non config-dependent Vagrantfiles
      loader = Config.new(self)
      loader.queue << File.expand_path("config/default.rb", Vagrant.source_root)
      loader.queue << File.join(box.directory, ROOTFILE_NAME) if !first_run && box
      loader.queue << File.join(home_path, ROOTFILE_NAME) if !first_run && home_path
      loader.queue << File.join(root_path, ROOTFILE_NAME) if root_path

      # If this environment is representing a sub-VM, then we push that
      # proc on as the last configuration.
      if !first_run && vm
        subvm = parent.config.vm.defined_vms[vm.name]
        loader.queue << subvm.proc_stack if subvm
      end

      # Execute the configuration stack and store the result as the final
      # value in the config ivar.
      @config = loader.load!

      # (re)load the logger
      @logger = nil

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
      all_keys = config.vm.defined_vms.keys
      all_keys = [DEFAULT_VM] if all_keys.empty?
      all_keys.each do |name|
        result[name] = Vagrant::VM.new(:name => name, :env => self) if !result.has_key?(name)
      end

      result
    end
  end
end
