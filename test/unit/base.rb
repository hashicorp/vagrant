require "rubygems"
require "rspec/autorun"

# Require Vagrant itself so we can reference the proper
# classes to test.
require "vagrant"

# Add the test directory to the load path
$:.unshift File.expand_path("../../", __FILE__)

# Load in helpers
require "support/tempdir"
require "unit/support/dummy_provider"
require "unit/support/shared/base_context"

# Do not buffer output
$stdout.sync = true
$stderr.sync = true

# Configure RSpec
RSpec.configure do |c|
  c.expect_with :rspec, :stdlib
end

# Configure VAGRANT_CWD so that the tests never find an actual
# Vagrantfile anywhere, or at least this minimizes those chances.
ENV["VAGRANT_CWD"] = Tempdir.new.path
