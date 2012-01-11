require File.expand_path("../../base", __FILE__)

describe "vagrant provisioning basics" do
  include_context "acceptance"

  it "doesn't provision with `--no-provision` set" do
    require_box("default")

    assert_execute("vagrant", "box", "add", "base", box_path("default"))

    environment.workdir.join("Vagrantfile").open("w+") do |f|
      f.write(<<-vf)
Vagrant::Config.run do |config|
  config.vm.box = "base"
  config.vm.provision :shell, :inline => "echo success > /vagrant/results"
end
vf
    end

    # Bring the VM up without enabling provisioning
    assert_execute("vagrant", "up", "--no-provision")

    # Verify the file that the script creates does NOT exist
    result_file = environment.workdir.join("results")
    result_file.exist?.should_not be
  end
end
