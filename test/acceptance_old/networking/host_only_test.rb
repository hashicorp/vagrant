require File.expand_path("../../base", __FILE__)

require "net/http"
require "uri"

require "acceptance/support/network_tests"
require "acceptance/support/shared/command_examples"
require "support/tempdir"

describe "vagrant host only networking" do
  include Acceptance::NetworkTests

  include_context "acceptance"

  def initialize_environment(env=nil)
    require_box("default")

    env ||= environment
    env.execute("vagrant", "box", "add", "base", box_path("default")).should succeed
  end

  it "creates a network with a static IP" do
    initialize_environment

    environment.workdir.join("Vagrantfile").open("w+") do |f|
      f.puts(<<VFILE)
Vagrant::Config.run do |config|
  config.vm.box = "base"
  config.vm.network :hostonly, "192.168.33.10"
end
VFILE
    end

    assert_execute("vagrant", "up")
    assert_host_to_vm_network("http://192.168.33.10:8000/", 8000)
  end
end
