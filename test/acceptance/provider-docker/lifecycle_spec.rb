# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

# This tests the basic functionality of a provider: that it can run
# a machine, provide SSH access, and destroy that machine.
shared_examples "provider/docker/lifecycle" do |provider, options|
  if provider != "docker"
    raise ArgumentError, 
      "provider must be docker to run tests" 
  end

  if !options[:image]
    raise ArgumentError,
      "box option must be specified for provider: #{provider}"
  end

  include_context "acceptance"

  before do
    environment.skeleton("basic_docker")
    ENV["VAGRANT_SPEC_DOCKER_IMAGE"] = options[:image]
  end

  let(:opts) { options }

  after do
    # Just always do this just in case
    execute("vagrant", "destroy", "--force", log: false)
  end

  def assert_running
    result = execute("docker", "ps", "--filter", "name=dockertest")
    expect(result).to exit_with(0)
    expect(result.stdout).to match(/#{opts[:image]}/)
  end

  def assert_not_running
    result = execute("docker", "ps", "--filter", "name=dockertest")
    expect(result).to exit_with(0)
    # Check the output ends with the last column of the header from the `docker ps`
    # command, indicating no images found.
    expect(result.stdout).to match(/NAMES\n$/)
  end

  context "after an up" do
    before do
      assert_execute("vagrant", "up", "--provider=#{provider}")
    end

    after do
      assert_execute("vagrant", "destroy", "--force")
    end

    it "can manage machine lifecycle" do
      status("Test: machine is running after up")
      assert_running

      status("Test: halt")
      assert_execute("vagrant", "halt")

      status("Test: ssh doesn't work during halted state")
      assert_not_running

      status("Test: up after halt")
      assert_execute("vagrant", "up")
      assert_running
    end
  end
end
