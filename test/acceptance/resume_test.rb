require File.expand_path("../base", __FILE__)
require "acceptance/support/shared/command_examples"

describe "vagrant resume" do
  include_context "acceptance"
  it_behaves_like "a command that requires a Vagrantfile", ["vagrant", "resume"]

  it "succeeds and ignores if the VM is not created" do
    require_box("default")

    assert_execute("vagrant", "box", "add", "base", box_path("default"))
    assert_execute("vagrant", "init")

    result = assert_execute("vagrant", "resume")
    result.stdout.should match_output(:vm_not_created_warning)
  end
end
