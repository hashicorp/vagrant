module Vagrant
  # Represents a single Vagrant environment. This class is responsible
  # for loading all of the Vagrantfile's for the given environment and
  # storing references to the various instances.
  class Environment
    ROOTFILE_NAME = "Vagrantfile"
    HOME_SUBDIRS = ["tmp", "boxes"]

    include Util

    attr_accessor :cwd
    attr_reader :root_path
    attr_reader :config
    attr_reader :box
    attr_accessor :vm
    attr_reader :ssh
    attr_reader :active_list
    attr_reader :commands

    #---------------------------------------------------------------
    # Class Methods
    #---------------------------------------------------------------
    class <<self
      # Loads and returns an environment given a specific working
      # directory. If a working directory is not given, it will default
      # to the pwd.
      def load!(cwd=nil)
        Environment.new(cwd).load!
      end

      # Verifies that VirtualBox is installed and that the version of
      # VirtualBox installed is high enough. Also verifies that the
      # configuration path is properly set.
      def check_virtualbox!
        version = VirtualBox.version
        if version.nil?
          error_and_exit(:virtualbox_not_detected)
        elsif version.to_f < 3.1
          error_and_exit(:virtualbox_invalid_version, :version => version.to_s)
        end
      end
    end

    def initialize(cwd=nil)
      @cwd = cwd
    end

    #---------------------------------------------------------------
    # Path Helpers
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
      File.join(root_path, config.vagrant.dotfile_name)
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
      load_ssh!
      load_active_list!
      load_commands!
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
      # Prepare load paths for config files
      load_paths = [File.join(PROJECT_ROOT, "config", "default.rb")]
      load_paths << File.join(box.directory, ROOTFILE_NAME) if box
      load_paths << File.join(home_path, ROOTFILE_NAME) if home_path
      load_paths << File.join(root_path, ROOTFILE_NAME) if root_path

      # Clear out the old data
      Config.reset!(self)

      # Load each of the config files in order
      load_paths.each do |path|
        if File.exist?(path)
          logger.info "Loading config from #{path}..."
          load path
        end
      end

      # Execute the configuration stack and store the result
      @config = Config.execute!
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
      return if !root_path || !File.file?(dotfile_path)

      File.open(dotfile_path) do |f|
        @vm = Vagrant::VM.find(f.read)
        @vm.env = self if @vm
      end
    rescue Errno::ENOENT
      @vm = nil
    end

    # Loads/initializes the SSH object
    def load_ssh!
      @ssh = SSH.new(self)
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

    #---------------------------------------------------------------
    # Methods to manage VM
    #---------------------------------------------------------------

    # Sets the VM to a new VM. This is not too useful but is used
    # in {Command.up}. This will very likely be refactored at a later
    # time.
    def create_vm
      @vm = VM.new
      @vm.env = self
      @vm
    end

    # Persists this environment's VM to the dotfile so it can be
    # re-loaded at a later time.
    def persist_vm
      # Save to the dotfile for this project
      File.open(dotfile_path, 'w+') do |f|
        f.write(vm.uuid)
      end

      # Also add to the global store
      active_list.add(vm)
    end

    # Removes this environment's VM from the dotfile.
    def depersist_vm
      # Delete the dotfile if it exists
      File.delete(dotfile_path) if File.exist?(dotfile_path)

      # Remove from the global store
      active_list.remove(vm)
    end

    #---------------------------------------------------------------
    # Methods to check for properties and error
    #---------------------------------------------------------------

    def require_root_path
      error_and_exit(:rootfile_not_found) if !root_path
    end

    def require_box
      require_root_path

      if !box
        if !Vagrant.config.vm.box
          error_and_exit(:box_not_specified)
        else
          error_and_exit(:box_specified_doesnt_exist, :box_name => Vagrant.config.vm.box)
        end
      end
    end

    def require_persisted_vm
      require_root_path

      error_and_exit(:environment_not_created) if !vm
    end
  end
end
