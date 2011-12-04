require "rubygems"
require "rspec/autorun"

# Require Vagrant itself so we can reference the proper
# classes to test.
require "vagrant"

# Do not buffer output
$stdout.sync = true
$stderr.sync = true

# Configure RSpec
RSpec.configure do |c|
  c.expect_with :rspec, :stdlib
end
