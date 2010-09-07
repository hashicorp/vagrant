# Add this folder to the load path for "test_helper"
$:.unshift(File.dirname(__FILE__))

require 'vagrant'
require 'mario'
require 'contest'
require 'mocha'
require 'support/path'
require 'support/environment'
require 'support/objects'

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
  include VagrantTestHelpers::Path
  include VagrantTestHelpers::Environment
  include VagrantTestHelpers::Objects

  # Mocks an environment, setting it up with the given config.
  def mock_environment
    environment = Vagrant::Environment.new
    environment.instance_variable_set(:@loaded, true)

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
      config.ssh.private_key_path = File.expand_path("keys/vagrant", Vagrant.source_root)

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
    environment.logger.class.reset_singleton_logger!
    environment.logger.stubs(:flush_progress)
    environment.logger.stubs(:cl_reset).returns("")

    environment
  end

  # Sets up the mocks for a VM
  def mock_vm(env=nil)
    env ||= vagrant_env
    vm = Vagrant::VM.new
    vm.stubs(:env).returns(env)
    vm.stubs(:ssh).returns(Vagrant::SSH.new(vm.env))
    vm
  end

  def mock_action_data(v_env=nil)
    v_env ||= vagrant_env
    app = lambda { |env| }
    env = Vagrant::Action::Environment.new(v_env)
    env["vagrant.test"] = true
    [app, env]
  end

  # Sets up the mocks and stubs for a downloader
  def mock_downloader(downloader_klass)
    tempfile = mock("tempfile")
    tempfile.stubs(:write)

    _, env = mock_action_data
    [downloader_klass.new(env), tempfile]
  end
end

