require "rubygems"
require "rspec/autorun"

require "log4r"

require File.expand_path("../support/base_context", __FILE__)
require File.expand_path("../support/config", __FILE__)
require File.expand_path("../support/virtualbox", __FILE__)

# If VirtualBox is currently running, fail.
if Acceptance::VirtualBox.find_vboxsvc
  $stderr.puts "VirtualBox must be closed and remain closed for the duration of the tests."
  abort
end

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
  abort
elsif !File.file?(ENV["ACCEPTANCE_CONFIG"])
  $stderr.puts "The configuration file must exist."
  abort
end

$acceptance_options = Acceptance::Config.new(ENV["ACCEPTANCE_CONFIG"])

# Configure RSpec
RSpec.configure do |c|
  c.expect_with :stdlib
end
