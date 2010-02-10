begin
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  # Fallback on doing the resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end

# ruby-debug, not necessary, but useful if we have it
begin
  require 'ruby-debug'
rescue LoadError; end


require File.join(File.dirname(__FILE__), '..', 'lib', 'vagrant')
require 'contest'
require 'mocha'

class Test::Unit::TestCase
  def mock_config
    Vagrant::Config.instance_variable_set(:@config_runners, nil)
    Vagrant::Config.instance_variable_set(:@config, nil)

    Vagrant::Config.run do |config|
      config.dotfile_name = ".hobo"

      config.ssh.username = "foo"
      config.ssh.password = "bar"
      config.ssh.host = "baz"
      config.ssh.forwarded_port_key = "ssh"
      config.ssh.max_tries = 10

      config.vm.base = "foo"
      config.vm.base_mac = "42"
      config.vm.project_directory = "/hobo"
      config.vm.forward_port("ssh", 22, 2222)

      config.chef.cookbooks_path = "cookbooks"
      config.chef.provisioning_path = "/tmp/hobo-chef"
      config.chef.json = {
        :recipes => ["hobo_main"]
      }
    end

    Vagrant::Config.execute!
  end
end
