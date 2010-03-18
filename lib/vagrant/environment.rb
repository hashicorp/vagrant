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
    attr_reader :vm

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
      load_vm!
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
      Config.reset!

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

      @box = Box.find(config.vm.box) if config.vm.box
    end

    # Loads the persisted VM (if it exists) for this environment.
    def load_vm!
      return if !root_path || !File.file?(dotfile_path)

      File.open(dotfile_path) do |f|
        @vm = Vagrant::VM.find(f.read)
      end
    rescue Errno::ENOENT
      @vm = nil
    end
  end
end