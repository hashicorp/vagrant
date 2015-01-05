require "tmpdir"
require "rubygems"

# Gems
require "checkpoint"
require "rspec/autorun"
require "webmock/rspec"

# Require Vagrant itself so we can reference the proper
# classes to test.
require "vagrant"
require "vagrant/util/platform"

# Add the test directory to the load path
$:.unshift File.expand_path("../../", __FILE__)

# Load in helpers
require "unit/support/dummy_communicator"
require "unit/support/dummy_provider"
require "unit/support/shared/base_context"
require "unit/support/shared/action_synced_folders_context"
require "unit/support/shared/capability_helpers_context"
require "unit/support/shared/plugin_command_context"
require "unit/support/shared/virtualbox_context"

# Do not buffer output
$stdout.sync = true
$stderr.sync = true

# Configure RSpec
RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true

  if Vagrant::Util::Platform.windows?
    c.filter_run_excluding :skip_windows
  else
    c.filter_run_excluding :windows
  end
end

# Configure VAGRANT_CWD so that the tests never find an actual
# Vagrantfile anywhere, or at least this minimizes those chances.
ENV["VAGRANT_CWD"] = Dir.mktmpdir("vagrant")

# Set the dummy provider to the default for tests
ENV["VAGRANT_DEFAULT_PROVIDER"] = "dummy"

# Unset all host plugins so that we aren't executing subprocess things
# to detect a host for every test.
Vagrant.plugin("2").manager.registered.dup.each do |plugin|
  if plugin.components.hosts.to_hash.length > 0
    Vagrant.plugin("2").manager.unregister(plugin)
  end
end

# Disable checkpoint
Checkpoint.disable!
