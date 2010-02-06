begin
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  # Fallback on doing the resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
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

      config.ssh.username = "foo"
      config.ssh.password = "bar"
      config.ssh.host = "baz"
      config.ssh.forwarded_port_key = "ssh"
      config.ssh.max_tries = 10

      config.vm.base = "foo"
      config.vm.base_mac = "42"
      config.vm.forward_port("ssh", 22, 2222)
    end

    Hobo::Config.execute!
  end
end
