# ruby-debug, not necessary, but useful if we have it
begin
  require 'ruby-debug'
rescue LoadError; end

require File.join(File.dirname(__FILE__), '..', 'lib', 'vagrant')
require 'contest'
require 'mocha'

# Add this folder to the load path for "test_helper"
$:.unshift(File.dirname(__FILE__))

class Test::Unit::TestCase
  # Mocks an environment, setting it up with the given config.
  def mock_environment
    environment = Vagrant::Environment.new

    Vagrant::Config.reset!(environment)

    Vagrant::Config.run do |config|
      config.vagrant.home = '~/.home'
      config.vagrant.dotfile_name = ".vagrant"
      config.vagrant.log_output = nil
      config.vagrant.host = :detect

      config.ssh.username = "foo"
      config.ssh.host = "baz"
      config.ssh.port = 22
      config.ssh.forwarded_port_key = "ssh"
      config.ssh.max_tries = 10
      config.ssh.timeout = 10
      config.ssh.private_key_path = '~/foo'

      config.vm.box = "foo"
      config.vm.box_url = nil
      config.vm.box_ovf = "box.ovf"
      config.vm.base_mac = "42"
      config.vm.disk_image_format = 'VMDK'
      config.vm.forward_port("ssh", 22, 2222)
      config.vm.shared_folder_uid = nil
      config.vm.shared_folder_gid = nil
      config.vm.system = :linux
      config.vm.share_folder("v-root", "/vagrant", ".")

      config.package.name = 'package'

      # Unison
      config.unison.folder_suffix = ".sync"
      config.unison.log_file = "foo-%s"

      # Chef
      config.chef.chef_server_url = "http://localhost:4000"
      config.chef.validation_key_path = "validation.pem"
      config.chef.client_key_path = "/zoo/foo/bar.pem"
      config.chef.node_name = "baz"
      config.chef.recipe_url = nil
      config.chef.cookbooks_path = "cookbooks"
      config.chef.provisioning_path = "/tmp/vagrant-chef"
      config.chef.log_level = :info
      config.chef.json = {
        :recipes => ["vagrant_main"]
      }
    end

    if block_given?
      Vagrant::Config.run do |config|
        yield config
      end
    end

    config = Vagrant::Config.execute!

    environment.instance_variable_set(:@config, config)

    # Setup the logger. We create it then reset it so that subsequent
    # calls will recreate it for us.
    environment.load_logger!
    environment.logger.class.reset_singleton_logger!
    environment.logger.stubs(:flush_progress)
    environment.logger.stubs(:cl_reset).returns("")

    environment
  end

  # Sets up the mocks for a VM
  def mock_vm(env=nil)
    env ||= mock_environment
    vm = Vagrant::VM.new
    vm.stubs(:env).returns(env)
    vm.stubs(:ssh).returns(Vagrant::SSH.new(vm.env))
    vm
  end

  def mock_action_data
    app = lambda { |env| }
    env = Vagrant::Action::Environment.new(mock_environment)
    env["vagrant.test"] = true
    [app, env]
  end

  # Returns a resource logger which is safe for tests
  def quiet_logger(resource, env=nil)
    logger = Vagrant::ResourceLogger.new(resource, env)
    logger.stubs(:flush_progress)
    logger.stubs(:cl_reset).returns("")
    logger
  end

  # Returns a linux system
  def linux_system(vm)
    Vagrant::Systems::Linux.new(vm)
  end

  def stub_default_action_dependecies(mock)
    mock.stubs(:precedes).returns([])
    mock.stubs(:follows).returns([])
  end

  # Sets up the mocks and stubs for a downloader
  def mock_downloader(downloader_klass)
    tempfile = mock("tempfile")
    tempfile.stubs(:write)

    _, env = mock_action_data
    [downloader_klass.new(env), tempfile]
  end
end

