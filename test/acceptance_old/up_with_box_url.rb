require File.expand_path("../base", __FILE__)
require "acceptance/support/shared/command_examples"

describe "vagrant up", "with a box URL set" do
  include_context "acceptance"

  it "downloads and brings up the VM if the box doesn't exist" do
    require_box("default")

    assert_execute("vagrant", "init", "base", box_path("default"))
    result = assert_execute("vagrant", "up")
    result.stdout.should match_output(:up_fetching_box, "base")
  end

  it "downloads the file only once and works if shared by multiple VMs", :issue => "GH-564" do
    require_box("default")

    environment.workdir.join("Vagrantfile").open("w+") do |f|
      f.puts(<<-VFILE)
Vagrant::Config.run do |config|
  config.vm.define :machine1 do |vm_config|
    vm_config.vm.box = "base"
    vm_config.vm.box_url = "#{box_path("default")}"
  end

  config.vm.define :machine2 do |vm_config|
    vm_config.vm.box = "base"
    vm_config.vm.box_url = "#{box_path("default")}"
  end
end
VFILE
    end

    # Bring up the environment, which should work. `machine1` should download
    # the box while `machine2` doesn't.
    result = assert_execute("vagrant", "up")
    result.stdout.should match_output(:up_fetching_box, "base", "machine1")
    result.stdout.should_not match_output(:up_fetching_box, "base", "machine2")
  end
end
