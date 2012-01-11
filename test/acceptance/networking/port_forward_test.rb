require File.expand_path("../../base", __FILE__)

require "net/http"
require "uri"

require "acceptance/support/network_tests"
require "acceptance/support/shared/command_examples"
require "support/tempdir"

describe "vagrant port forwarding" do
  include Acceptance::NetworkTests

  include_context "acceptance"

  def initialize_environment(env=nil)
    require_box("default")

    env ||= environment
    env.execute("vagrant", "box", "add", "base", box_path("default")).should succeed
  end

  it "forwards ports properly" do
    initialize_environment

    guest_port = 3000
    host_port  = 5000

    environment.workdir.join("Vagrantfile").open("w+") do |f|
      f.puts(<<VFILE)
Vagrant::Config.run do |config|
  config.vm.box = "base"
  config.vm.forward_port #{guest_port}, #{host_port}
end
VFILE
    end

    assert_execute("vagrant", "up")
    assert_host_to_vm_network("http://localhost:#{host_port}/", guest_port)
  end

  it "properly overrides port forwarding from the same port" do
    initialize_environment

    guest_port = 3000
    host_port  = 5000

    environment.workdir.join("Vagrantfile").open("w+") do |f|
      f.puts(<<VFILE)
Vagrant::Config.run do |config|
  config.vm.box = "base"
  config.vm.forward_port #{guest_port}, #{host_port - 1}
  config.vm.forward_port #{guest_port}, #{host_port}
end
VFILE
    end

    assert_execute("vagrant", "up")
    assert_host_to_vm_network("http://localhost:#{host_port}/", guest_port)
  end

  it "detects and corrects port collisions" do
    # The two environments need to share a VBOX_USER_HOME so that the
    # VM's go into the same place.
    env_vars     = { "VBOX_USER_HOME" => Tempdir.new("vagrant").to_s }
    environment  = new_environment(env_vars)
    environment2 = new_environment(env_vars)

    # For this test we create two isolated environments and `vagrant up`
    # in each. SSH would collide, so this verifies that it won't!
    begin
      initialize_environment(environment)
      initialize_environment(environment2)

      # Build both environments up.
      environment.execute("vagrant", "init").should succeed
      environment.execute("vagrant", "up").should succeed
      environment2.execute("vagrant", "init").should succeed
      environment2.execute("vagrant", "up").should succeed

      # Touch files in both environments
      environment.execute("vagrant", "ssh", "-c", "touch /vagrant/foo").should succeed
      environment2.execute("vagrant", "ssh", "-c", "touch /vagrant/bar").should succeed

      # Verify that the files exist in each folder, properly
      environment.workdir.join("foo").exist?.should be
      environment2.workdir.join("bar").exist?.should be
    ensure
      environment.close
      environment2.close
    end
  end

  it "refuses to resume if there is a port collision" do
    # The two environments need to share a VBOX_USER_HOME so that the
    # VM's go into the same place.
    env_vars     = { "VBOX_USER_HOME" => Tempdir.new("vagrant").path }
    environment  = new_environment(env_vars)
    environment2 = new_environment(env_vars)

    # For this test we `vagrant up` one environment, suspend it,
    # `vagrant up` another environment, and then come back to the first
    # and try to resume. SSH would collide so it should error.
    begin
      # Bring up the first environment and suspend it
      initialize_environment(environment)
      environment.execute("vagrant", "init").should succeed
      environment.execute("vagrant", "up").should succeed
      environment.execute("vagrant", "suspend").should succeed

      # Bring up the second environment
      initialize_environment(environment2)
      environment2.execute("vagrant", "init").should succeed
      environment2.execute("vagrant", "up").should succeed

      # Attempt to bring up the first environment again, but it should
      # result in an error.
      result = environment.execute("vagrant", "up")
      result.should_not succeed
      result.stderr.should match_output(:resume_port_collision)
    ensure
      environment.close
      environment2.close
    end
  end
end
