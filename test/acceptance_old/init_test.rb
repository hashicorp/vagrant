require File.expand_path("../base", __FILE__)

describe "vagrant init" do
  include_context "acceptance"

  it "creates a Vagrantfile in the working directory" do
    vagrantfile = environment.workdir.join("Vagrantfile")
    vagrantfile.exist?.should_not be, "Vagrantfile shouldn't exist initially"

    result = execute("vagrant", "init")
    result.should succeed
    vagrantfile.exist?.should be, "Vagrantfile should exist"
  end

  it "creates a Vagrantfile with the box set to the given argument" do
    vagrantfile = environment.workdir.join("Vagrantfile")

    result = execute("vagrant", "init", "foo")
    result.should succeed
    vagrantfile.read.should match(/config.vm.box = "foo"$/)
  end

  it "creates a Vagrantfile with the box URL set to the given argument" do
    vagrantfile = environment.workdir.join("Vagrantfile")

    result = execute("vagrant", "init", "foo", "bar")
    result.should succeed

    contents = vagrantfile.read
    contents.should match(/config.vm.box = "foo"$/)
    contents.should match(/config.vm.box_url = "bar"$/)
  end
end
