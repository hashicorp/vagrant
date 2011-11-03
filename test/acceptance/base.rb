require "contest"
require "log4r"

require File.expand_path("../helpers/isolated_environment", __FILE__)
require File.expand_path("../helpers/config.rb", __FILE__)

# Enable logging if requested
if ENV["ACCEPTANCE_LOGGING"]
  logger = Log4r::Logger.new("acceptance")
  logger.outputters = Log4r::Outputter.stdout
  logger.level = Log4r.const_get(ENV["ACCEPTANCE_LOGGING"].upcase)
  logger = nil
end

# Parse the command line options and load the global configuration.
if !ENV.has_key?("ACCEPTANCE_CONFIG")
  $stderr.puts "A configuration file must be passed into the acceptance test."
  exit
elsif !File.file?(ENV["ACCEPTANCE_CONFIG"])
  $stderr.puts "The configuration file must exist."
  exit
end

$acceptance_options = Acceptance::Config.new(ENV["ACCEPTANCE_CONFIG"])

class AcceptanceTest < Test::Unit::TestCase
  # This method is a shortcut to give access to the global configuration
  # setup by the acceptance tests.
  def config
    $acceptance_options
  end

  # Executes the given command in the isolated environment. This
  # is just a shortcut to IsolatedEnvironment#execute.
  #
  # @return [Object]
  def execute(*args)
    @environment.execute(*args)
  end

  setup do
    # Setup the environment so that we have an isolated area
    # to run Vagrant. We do some configuration here as well in order
    # to replace "vagrant" with the proper path to Vagrant as well
    # as tell the isolated environment about custom environmental
    # variables to pass in.
    apps = { "vagrant" => config.vagrant_path }
    @environment = Acceptance::IsolatedEnvironment.new(apps, config.env)
  end

  teardown do
    @environment.close
  end
end
