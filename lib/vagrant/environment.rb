require 'pathname'
require 'fileutils'

module Vagrant
  # Represents a single Vagrant environment. This class is responsible
  # for loading all of the Vagrantfile's for the given environment and
  # storing references to the various instances.
  class Environment
    ROOTFILE_NAME = "Vagrantfile"
    HOME_SUBDIRS = ["tmp", "boxes"]
    DEFAULT_VM = :default

    attr_reader :parent     # Parent environment (in the case of multi-VMs)
    attr_reader :vm_name    # The name of the VM (internal name) which this environment represents

    attr_reader :cwd
    attr_reader :root_path
    attr_reader :config
    attr_reader :box
    attr_accessor :vm
    attr_writer :ui

    #---------------------------------------------------------------
    # Class Methods
    #---------------------------------------------------------------
    class << self
      # Loads and returns an environment given a specific working
      # directory. If a working directory is not given, it will default
      # to the pwd.
      def load!(cwd=nil)
        Environment.new(:cwd => cwd).load!
      end

      # Verifies that VirtualBox is installed and that the version of
      # VirtualBox installed is high enough. Also verifies that the
      # configuration path is properly set.
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
        :vm_name => nil,
        :vm => nil,
        :cwd => Dir.pwd
      }.merge(opts || {})

      opts.each do |key, value|
        instance_variable_set("@#{key}".to_sym, opts[key])
      end
    end

    #---------------------------------------------------------------
    # Helpers
    #---------------------------------------------------------------

    # The path to the `dotfile`, which contains the persisted UUID of
    # the VM if it exists.
    def dotfile_path
      root_path ? File.join(root_path, config.vagrant.dotfile_name) : nil
    end

    # The path to the home directory, which is usually in `~/.vagrant/~
    def home_path
      config ? config.vagrant.home : nil
    end

    # The path to the Vagrant tmp directory
    def tmp_path
      File.join(home_path, "tmp")
    end

    # The path to the Vagrant boxes directory
    def boxes_path
      File.join(home_path, "boxes")
    end

    # Returns the name of the resource which this environment represents.
    # The resource is the VM name if there is a VM it represents, otherwise
    # it defaults to "vagrant"
    def resource
      vm_name || "vagrant"
    end

    # Returns the VMs associated with this environment.
    def vms
      @vms ||= {}
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

    #---------------------------------------------------------------
    # Load Methods
    #---------------------------------------------------------------

    # Loads this entire environment, setting up the instance variables
    # such as `vm`, `config`, etc. on this environment. The order this
    # method calls its other methods is very particular.
    def load!
      load_root_path!
      load_config!
      load_home_directory!
      load_box!
      load_config!
      self.class.check_virtualbox!
      load_vm!
      self
    end

    # Loads the root path of this environment, given the starting
    # directory (the "cwd" of this environment for lack of better words).
    # This method allows an environment in `/foo` to be detected from
    # `/foo/bar` (similar to how git works in subdirectories)
    def load_root_path!(path=nil)
      path = Pathname.new(File.expand_path(path || cwd))

      # Stop if we're at the root.
      return false if path.root?

      file = "#{path}/#{ROOTFILE_NAME}"
      if File.exist?(file)
        @root_path = path.to_s
        return true
      end

      load_root_path!(path.parent)
    end

    # Loads this environment's configuration and stores it in the {config}
    # variable. The configuration loaded by this method is specified to
    # this environment, meaning that it will use the given root directory
    # to load the Vagrantfile into that context.
    def load_config!
      # Prepare load paths for config files and append to config queue
      config_queue = [File.expand_path("config/default.rb", Vagrant.source_root)]
      config_queue << File.join(box.directory, ROOTFILE_NAME) if box
      config_queue << File.join(home_path, ROOTFILE_NAME) if home_path
      config_queue << File.join(root_path, ROOTFILE_NAME) if root_path

      # If this environment represents some VM in a multi-VM environment,
      # we push that VM's configuration onto the config_queue.
      if vm_name
        subvm = parent.config.vm.defined_vms[vm_name]
        config_queue << subvm.proc_stack if subvm
      end

      # Flatten the config queue so any nested procs are flattened
      config_queue.flatten!

      # Clear out the old data
      Config.reset!(self)

      # Load each of the config files in order
      config_queue.each do |item|
        if item.is_a?(String) && File.exist?(item)
          load item
          next
        end

        if item.is_a?(Proc)
          # Just push the proc straight onto the config runnable stack
          Config.run(&item)
        end
      end

      # Execute the configuration stack and store the result
      @config = Config.execute!

      # (re)load the logger
      @logger = nil
    end

    # Loads the home directory path and creates the necessary subdirectories
    # within the home directory if they're not already created.
    def load_home_directory!
      # Setup the array of necessary home directories
      dirs = HOME_SUBDIRS.collect { |subdir| File.join(home_path, subdir) }
      dirs.unshift(home_path)

      # Go through each required directory, creating it if it doesn't exist
      dirs.each do |dir|
        next if File.directory?(dir)

        logger.info "Creating home directory since it doesn't exist: #{dir}"
        FileUtils.mkdir_p(dir)
      end
    end

    # Loads the specified box for this environment.
    def load_box!
      return unless root_path

      @box = Box.find(self, config.vm.box) if config.vm.box
    end

    # Loads the persisted VM (if it exists) for this environment.
    def load_vm!
      # This environment represents a single sub VM. The VM is then
      # probably (read: should be) set on the VM attribute, so we do
      # nothing.
      return if vm_name

      # First load the defaults (blank, noncreated VMs)
      load_blank_vms!

      # Load the VM UUIDs from the local data store
      (local_data[:active] || {}).each do |name, uuid|
        vms[name.to_sym] = Vagrant::VM.find(uuid, self, name.to_sym)
      end
    end

    # Loads blank VMs into the `vms` attribute.
    def load_blank_vms!
      # Clear existing vms
      vms.clear

      # Load up the blank VMs
      defined_vms = config.vm.defined_vms.keys
      defined_vms = [DEFAULT_VM] if defined_vms.empty?

      defined_vms.each do |name|
        vms[name] = Vagrant::VM.new(:vm_name => name, :env => self)
      end
    end
  end
end
