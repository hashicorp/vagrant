require File.expand_path("../base", __FILE__)
require "acceptance/support/shared/command_examples"

describe "vagrant package" do
  include_context "acceptance"
  it_behaves_like "a command that requires a Vagrantfile", ["vagrant", "package"]

  # This creates an initial environment that is ready for a "vagrant up"
  def initialize_valid_environment
    require_box("default")

    assert_execute("vagrant", "box", "add", "base", box_path("default"))
    assert_execute("vagrant", "init")
  end

  it "can package a running virtual machine" do
    initialize_valid_environment

    assert_execute("vagrant", "up")
    assert_execute("vagrant", "package")
    environment.workdir.join("package.box").should be_file
  end
end
