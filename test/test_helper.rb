# Add this folder to the load path for "test_helper"
$:.unshift(File.dirname(__FILE__))

require 'vagrant'
require 'mario'
require 'contest'
require 'mocha'

# Try to load ruby debug since its useful if it is available.
# But not a big deal if its not available (probably on a non-MRI
# platform)
begin
  require 'ruby-debug'
rescue LoadError
end

# Silence Mario by sending log output to black hole
Mario::Platform.logger(nil)

# Add the I18n locale for tests
I18n.load_path << File.expand_path("../locales/en.yml", __FILE__)

class Test::Unit::TestCase
  include Vagrant::TestHelpers

  # Sets up the mocks and stubs for a downloader
  def mock_downloader(downloader_klass)
    tempfile = mock("tempfile")
    tempfile.stubs(:write)

    _, env = action_env
    [downloader_klass.new(env), tempfile]
  end
end

