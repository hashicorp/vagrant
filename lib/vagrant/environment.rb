module Vagrant
  # Represents a single Vagrant environment. This class is responsible
  # for loading all of the Vagrantfile's for the given environment and
  # storing references to the various instances.
  class Environment
    ROOTFILE_NAME = "Vagrantfile"
    HOME_SUBDIRS = ["tmp", "boxes"]
    DEFAULT_VM = :default

    include Util

    attr_reader :parent     # Parent environment (in the case of multi-VMs)
    attr_reader :vm_name    # The name of the VM (internal name) which this environment represents

    attr_accessor :cwd
    attr_reader :root_path
    attr_reader :config
    attr_reader :host
    attr_reader :box
    attr_accessor :vm
    attr_reader :vms
    attr_reader :active_list
    attr_reader :commands
    attr_reader :logger
    attr_reader :actions

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
        if version.nil?
          error_and_exit(:virtualbox_not_detected)
        elsif version.to_f < 3.2
          error_and_exit(:virtualbox_invalid_version, :version => version.to_s)
        elsif version.to_s.downcase.include?("ose")
          error_and_exit(:virtualbox_invalid_ose, :version => version.to_s)
        end
      end
    end

    def initialize(opts=nil)
      defaults = {
        :parent => nil,
        :vm_name => nil,
        :vm => nil,
        :cwd => nil
      }

      opts = defaults.merge(opts || {})

      defaults.each do |key, value|
        instance_variable_set("@#{key}".to_sym, opts[key])
      end
    end

    #---------------------------------------------------------------
    # Helpers
    #---------------------------------------------------------------

    # Specifies the "current working directory" for this environment.
    # This is vital in determining the root path and therefore the
    # dotfile, rootpath vagrantfile, etc. This defaults to the
    # actual cwd (`Dir.pwd`).
    def cwd
      @cwd || Dir.pwd
    end

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

    #---------------------------------------------------------------
    # Load Methods
    #---------------------------------------------------------------

    # Loads this entire environment, setting up the instance variables
    # such as `vm`, `config`, etc. on this environment. The order this
    # method calls its other methods is very particular.
    def load!
      load_logger!
      load_root_path!
      load_config!
      load_home_directory!
      load_host!
      load_box!
      load_config!
      self.class.check_virtualbox!
      load_vm!
      load_active_list!
      load_commands!
      load_actions!
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
      config_queue = [File.join(PROJECT_ROOT, "config", "default.rb")]
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
      load_logger!
    end

    # Loads the logger for this environment. This is called by
    # {#load_config!} so that the logger is only loaded after
    # configuration information is available. The logger is also
    # loaded early on in the load chain process so that the various
    # references to logger won't throw nil exceptions, but by default
    # the logger will just send the log data to a black hole.
    def load_logger!
      resource = vm_name || "vagrant"
      @logger = Util::ResourceLogger.new(resource, self)
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

    # Loads the host class for this environment.
    def load_host!
      @host = Hosts::Base.load(self, config.vagrant.host)
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

      # If we have no dotfile, then return
      return if !dotfile_path || !File.file?(dotfile_path)

      # Open and parse the dotfile
      File.open(dotfile_path) do |f|
        data = { DEFAULT_VM => f.read }

        begin
          data = JSON.parse(data[DEFAULT_VM])
        rescue JSON::ParserError
          # Most likely an older (<= 0.3.x) dotfile. Try to load it
          # as the :__vagrant VM.
        end

        data.each do |key, value|
          key = key.to_sym
          vms[key] = Vagrant::VM.find(value, self, key)
        end
      end
    rescue Errno::ENOENT
      # Just rescue it.
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

    # Loads the activelist for this environment
    def load_active_list!
      @active_list = ActiveList.new(self)
    end

    # Loads the instance of {Command} for this environment. This allows
    # users of the instance to run commands such as "up" "down" etc. in
    # the context of this environment.
    def load_commands!
      @commands = Command.new(self)
    end

    # Loads the instance of {Action} for this environment. This allows
    # users of the instance to run action sequences in the context of
    # this environment.
    def load_actions!
      @actions = Action.new(self)
    end

    #---------------------------------------------------------------
    # Methods to manage VM
    #---------------------------------------------------------------

    # Persists this environment's VM to the dotfile so it can be
    # re-loaded at a later time.
    def update_dotfile
      return parent.update_dotfile if parent

      # Generate and save the persisted VM info
      data = vms.inject({}) do |acc, data|
        key, value = data
        acc[key] = value.uuid if value.created?
        acc
      end

      if data.empty?
        File.delete(dotfile_path) if File.exist?(dotfile_path)
      else
        File.open(dotfile_path, 'w+') do |f|
          f.write(data.to_json)
        end
      end

      # Also add to the global store
      # active_list.add(vm)
    end

    #---------------------------------------------------------------
    # Methods to check for properties and error
    #---------------------------------------------------------------

    def require_root_path
      error_and_exit(:rootfile_not_found) if !root_path
    end

    def require_persisted_vm
      require_root_path

      error_and_exit(:environment_not_created) if !vm
    end
  end
end
