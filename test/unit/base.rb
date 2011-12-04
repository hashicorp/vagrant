require "rubygems"
require "rspec/autorun"

# Require Vagrant itself so we can reference the proper
# classes to test.
require "vagrant"

# Add this directory to the load path, since it just makes
# everything else easier.
$:.unshift File.expand_path("../", __FILE__)
$:.unshift File.expand_path("../../", __FILE__)

# Load in helpers
require "support/shared/base_context"

# Do not buffer output
$stdout.sync = true
$stderr.sync = true

# Configure RSpec
RSpec.configure do |c|
  c.expect_with :rspec, :stdlib
end
