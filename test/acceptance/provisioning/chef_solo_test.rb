require File.expand_path("../../base", __FILE__)

describe "vagrant provisioning with chef solo" do
  include_context "acceptance"

  it "runs basic cookbooks" do
    # Create the chef solo basic skeleton
    environment.skeleton!("chef_solo_basic")

    # Setup the basic environment
    require_box("default")
    assert_execute("vagrant", "box", "add", "base", box_path("default"))

    # Bring up the VM
    assert_execute("vagrant", "up")

    # Check for the file it should have created
    results = assert_execute("vagrant", "ssh", "-c", "cat /tmp/chef_solo_basic")
    results.stdout.should == "success"
  end

  it "merges JSON into the attributes" do
    # Copy the skeleton
    environment.skeleton!("chef_solo_json")

    # Setup the basic environment
    require_box("default")
    assert_execute("vagrant", "box", "add", "base", box_path("default"))

    # Bring up the VM
    assert_execute("vagrant", "up")

    # Check for the file it should have created
    results = assert_execute("vagrant", "ssh", "-c", "cat /tmp/chef_solo_basic")
    results.stdout.should == "json_data"
  end
end
