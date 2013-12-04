require "rubygems"
require "rspec/autorun"

require "log4r"

# Add the test directory to the load path
$:.unshift File.expand_path("../../", __FILE__)

# Load in the supporting files for our tests
require "acceptance/support/shared/base_context"
require "acceptance/support/config"
require "acceptance/support/virtualbox"
require "acceptance/support/matchers/match_output"
require "acceptance/support/matchers/succeed"

# Do not buffer output
$stdout.sync = true
$stderr.sync = true

# If VirtualBox is currently running, fail.
if Acceptance::VirtualBox.find_vboxsvc
  $stderr.puts "VirtualBox must be closed and remain closed for the duration of the tests."
  abort
end

# Enable logging if requested
if ENV["ACCEPTANCE_LOG"]
  logger = Log4r::Logger.new("test")
  logger.outputters = Log4r::Outputter.stdout
  logger.level = Log4r.const_get(ENV["ACCEPTANCE_LOG"].upcase)
  logger = nil
end

# Parse the command line options and load the global configuration.
if !ENV.has_key?("ACCEPTANCE_CONFIG")
  $stderr.puts "A configuration file must be passed into the acceptance test."
  abort
elsif !File.file?(ENV["ACCEPTANCE_CONFIG"])
  $stderr.puts "The configuration file must exist."
  abort
end

$acceptance_options = Acceptance::Config.new(ENV["ACCEPTANCE_CONFIG"])

# Configure RSpec
RSpec.configure do |c|
  c.expect_with :rspec, :stdlib
end
