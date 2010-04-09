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
  # Mocks an environment, setting it up with the given config.
  def mock_environment
    environment = Vagrant::Environment.new

    Vagrant::Config.reset!(environment)

    Vagrant::Config.run do |config|
      config.vagrant.dotfile_name = ".vagrant"

      config.ssh.username = "foo"
      config.ssh.password = "bar"
      config.ssh.host = "baz"
      config.ssh.forwarded_port_key = "ssh"
      config.ssh.max_tries = 10
      config.ssh.timeout = 10
      config.ssh.private_key_path = '~/foo'

      config.vm.box = "foo"
      config.vm.box_ovf = "box.ovf"
      config.vm.base_mac = "42"
      config.vm.project_directory = "/vagrant"
      config.vm.disk_image_format = 'VMDK'
      config.vm.forward_port("ssh", 22, 2222)
      config.vm.shared_folder_uid = nil
      config.vm.shared_folder_gid = nil

      config.package.name = 'vagrant'
      config.package.extension = '.box'

      # Chef
      config.chef.chef_server_url = "http://localhost:4000"
      config.chef.validation_key_path = "validation.pem"
      config.chef.client_key_path = "/zoo/foo/bar.pem"
      config.chef.node_name = "baz"
      config.chef.cookbooks_path = "cookbooks"
      config.chef.provisioning_path = "/tmp/vagrant-chef"
      config.chef.log_level = :info
      config.chef.json = {
        :recipes => ["vagrant_main"]
      }

      config.vagrant.home = '~/.home'
    end

    if block_given?
      Vagrant::Config.run do |config|
        yield config
      end
    end

    config = Vagrant::Config.execute!

    environment.instance_variable_set(:@config, config)
    environment
  end

  # Sets up the mocks and instantiates an action for testing
  def mock_action(action_klass, *args)
    vm = mock("vboxvm")
    mock_vm = mock("vm")
    action = action_klass.new(mock_vm, *args)
    stub_default_action_dependecies(action)

    mock_vm.stubs(:vm).returns(vm)
    mock_vm.stubs(:vm=)
    mock_vm.stubs(:invoke_callback)
    mock_vm.stubs(:invoke_around_callback).yields
    mock_vm.stubs(:actions).returns([action])
    mock_vm.stubs(:env).returns(mock_environment)

    [mock_vm, vm, action]
  end

  def stub_default_action_dependecies(mock)
    mock.stubs(:precedes).returns([])
    mock.stubs(:follows).returns([])
  end

  # Sets up the mocks and stubs for a downloader
  def mock_downloader(downloader_klass)
    tempfile = mock("tempfile")
    tempfile.stubs(:write)

    [downloader_klass.new, tempfile]
  end
end

