require "fileutils"
require "pathname"
require "tmpdir"

require "log4r"

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
  def initialize
    @logger = Log4r::Logger.new("test::isolated_environment")

    # Create a temporary directory for our work
    @tempdir = Dir.mktmpdir("vagrant")
    @logger.info("Initialize isolated environment: #{@tempdir}")

    # Setup the home and working directories
    @homedir = Pathname.new(File.join(@tempdir, "home"))
    @workdir = Pathname.new(File.join(@tempdir, "work"))

    @homedir.mkdir
    @workdir.mkdir
  end

  # This closes the environment by cleaning it up.
  def close
    @logger.info("Removing isolated environment: #{@tempdir}")
    FileUtils.rm_rf(@tempdir)
  end
end
