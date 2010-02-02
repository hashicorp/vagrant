 begin
  require File.join(File.dirname(__FILE__), '..', 'vendor', 'gems', 'environment')
rescue LoadError
  puts <<-ENVERR
==================================================
ERROR: Gem environment file not found!

Hobo uses bundler to handle gem dependencies. To setup the
test environment, please run `gem bundle test` If you don't
have bundler, you can install that with `gem install bundler`
==================================================
ENVERR
  exit
end

# This silences logger output
ENV['HOBO_ENV'] = 'test'

# ruby-debug, not necessary, but useful if we have it
begin
  require 'ruby-debug'
rescue LoadError; end


require File.join(File.dirname(__FILE__), '..', 'lib', 'hobo')
require 'contest'
require 'mocha'

class Test::Unit::TestCase
  def hobo_mock_config
    Hobo::Config.instance_variable_set(:@config_runners, nil)
    Hobo::Config.instance_variable_set(:@config, nil)

    Hobo::Config.run do |config|
      config.dotfile_name = ".hobo"

      config.ssh.uname = "foo"
      config.ssh.pass = "bar"
      config.ssh.host = "baz"
      config.ssh.port = "bak"
      config.ssh.max_tries = 10

      config.vm.base = "foo"
      config.vm.base_mac = "42"
    end

    Hobo::Config.execute!
  end
end
