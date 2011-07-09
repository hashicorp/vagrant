# Add this folder to the load path for "test_helper"
$:.unshift(File.dirname(__FILE__))

require 'vagrant'
require 'contest'
require 'mocha'

# Try to load ruby debug since its useful if it is available.
# But not a big deal if its not available (probably on a non-MRI
# platform)
begin
  require 'ruby-debug'
rescue LoadError
end

# Add the I18n locale for tests
I18n.load_path << File.expand_path("../locales/en.yml", __FILE__)

class Test::Unit::TestCase
  include Vagrant::TestHelpers
end

