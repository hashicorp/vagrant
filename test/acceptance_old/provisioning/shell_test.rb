require File.expand_path("../../base", __FILE__)

describe "vagrant provisioning with shell" do
  include_context "acceptance"

  it "runs a script on boot" do
    require_box("default")

    assert_execute("vagrant", "box", "add", "base", box_path("default"))

    environment.workdir.join("Vagrantfile").open("w+") do |f|
      f.write(<<-vf)
Vagrant::Config.run do |config|
  config.vm.box = "base"
  config.vm.provision :shell, :path => "script.sh"
end
vf
    end

    environment.workdir.join("script.sh").open("w+") do |f|
      f.write(<<-vf)
echo success > /vagrant/results
vf
    end

    assert_execute("vagrant", "up")

    result_file = environment.workdir.join("results")
    result_file.exist?.should be
    result_file.read.should == "success\n"
  end

  it "runs an inline script" do
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

    assert_execute("vagrant", "up")

    result_file = environment.workdir.join("results")
    result_file.exist?.should be
    result_file.read.should == "success\n"
  end
end
