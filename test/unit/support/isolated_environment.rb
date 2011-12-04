require "fileutils"
require "pathname"

require "log4r"

require "support/tempdir"

module Unit
  # This class manages an isolated environment for Vagrant to
  # run in. It creates a temporary directory to act as the
  # working directory as well as sets a custom home directory.
  #
  # This class also provides various helpers to create Vagrantfiles,
  # boxes, etc.
  class IsolatedEnvironment
    attr_reader :homedir
    attr_reader :workdir

    # Initializes an isolated environment. You can pass in some
    # options here to configure runing custom applications in place
    # of others as well as specifying environmental variables.
    #
    # @param [Hash] apps A mapping of application name (such as "vagrant")
    #   to an alternate full path to the binary to run.
    # @param [Hash] env Additional environmental variables to inject
    #   into the execution environments.
    def initialize(apps=nil, env=nil)
      @logger = Log4r::Logger.new("unit::isolated_environment")

      # Create a temporary directory for our work
      @tempdir = Tempdir.new("vagrant")
      @logger.info("Initialize isolated environment: #{@tempdir.path}")

      # Setup the home and working directories
      @homedir = Pathname.new(File.join(@tempdir.path, "home"))
      @workdir = Pathname.new(File.join(@tempdir.path, "work"))

      @homedir.mkdir
      @workdir.mkdir
    end

    def create_vagrant_env
      Vagrant::Environment.new(:cwd => @workdir, :home_path => @homedir)
    end

    def vagrantfile(contents, root=nil)
      root ||= @workdir
      root.join("Vagrantfile").open("w+") do |f|
        f.write(contents)
      end
    end

    def box(name, vagrantfile_contents="")
      box_dir = boxes_dir.join(name)
      box_dir.mkpath
      vagrantfile(vagrantfile_contents, box_dir)
    end

    def boxes_dir
      dir = @homedir.join("boxes")
      dir.mkpath
      dir
    end
  end
end
