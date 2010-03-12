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
  # Clears the previous config and sets up the new config
  def mock_config
    Vagrant::Config.reset!

    Vagrant::Config.run do |config|
      config.vagrant.dotfile_name = ".hobo"

      config.ssh.username = "foo"
      config.ssh.password = "bar"
      config.ssh.host = "baz"
      config.ssh.forwarded_port_key = "ssh"
      config.ssh.max_tries = 10
      config.ssh.timeout = 10
      config.ssh.retry_timeout_delta = 5
      config.ssh.max_timeout_delta = 30

      config.vm.box = "foo"
      config.vm.box_ovf = "box.ovf"
      config.vm.base_mac = "42"
      config.vm.project_directory = "/hobo"
      config.vm.disk_image_format = 'VMDK'
      config.vm.forward_port("ssh", 22, 2222)

      config.package.name = 'vagrant'
      config.package.extension = '.box'

      config.chef.cookbooks_path = "cookbooks"
      config.chef.provisioning_path = "/tmp/hobo-chef"
      config.chef.json = {
        :recipes => ["hobo_main"]
      }

      config.vagrant.home = '~/.home'
    end

    if block_given?
      Vagrant::Config.run do |config|
        yield config
      end
    end

    if block_given?
      Vagrant::Config.run do |config|
        yield config
      end
    end

    Vagrant::Config.execute!
  end

  # Sets up the mocks and instantiates an action for testing
  def mock_action(action_klass, *args)
    vm = mock("vboxvm")
    mock_vm = mock("vm")
    action = action_klass.new(mock_vm, *args)

    mock_vm.stubs(:vm).returns(vm)
    mock_vm.stubs(:vm=)
    mock_vm.stubs(:invoke_callback)
    mock_vm.stubs(:invoke_around_callback).yields
    mock_vm.stubs(:actions).returns([action])

    [mock_vm, vm, action]
  end

  # Sets up the mocks and stubs for a downloader
  def mock_downloader(downloader_klass)
    tempfile = mock("tempfile")
    tempfile.stubs(:write)

    [downloader_klass.new, tempfile]
  end
end
