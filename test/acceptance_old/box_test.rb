require File.expand_path("../base", __FILE__)

describe "vagrant box" do
  include_context "acceptance"

  it "has no boxes by default" do
    result = execute("vagrant", "box", "list")
    result.stdout.should match_output(:no_boxes)
  end

  it "can add a box from a file" do
    require_box("default")

    # Add the box, which we expect to succeed
    result = execute("vagrant", "box", "add", "foo", box_path("default"))
    result.should succeed

    # Verify that the box now shows up in the list of available boxes
    result = execute("vagrant", "box", "list")
    result.stdout.should match_output(:box_installed, "foo")
  end

  it "errors if attempting to add a box with the same name" do
    require_box("default")

    # Add the box, which we expect to succeed
    assert_execute("vagrant", "box", "add", "foo", box_path("default"))

    # Adding it again should not succeed
    result = execute("vagrant", "box", "add", "foo", box_path("default"))
    result.should_not succeed
    result.stderr.should match_output(:box_already_exists, "foo")
  end

  it "overwrites a box when adding with `--force`" do
    require_box("default")

    # Add the box, which we expect to succeed
    assert_execute("vagrant", "box", "add", "foo", box_path("default"))

    # Adding it again should not succeed
    assert_execute("vagrant", "box", "add", "foo", box_path("default"), "--force")
  end

  it "gives an error if the file doesn't exist" do
    result = execute("vagrant", "box", "add", "foo", "/tmp/nope/nope/nope/nonono.box")
    result.should_not succeed
    result.stderr.should match_output(:box_path_doesnt_exist)
  end

  it "gives an error if the file is not a valid box" do
    invalid = environment.workdir.join("nope.txt")
    invalid.open("w+") do |f|
      f.write("INVALID!")
    end

    result = execute("vagrant", "box", "add", "foo", invalid.to_s)
    result.should_not succeed
    result.stderr.should match_output(:box_invalid)
  end

  it "can add a box from an HTTP server" do
    pending("Need to setup HTTP server functionality")
  end

  it "can remove a box" do
    require_box("default")

    # Add the box, remove the box, then verify that the box no longer
    # shows up in the list of available boxes.
    execute("vagrant", "box", "add", "foo", box_path("default"))
    execute("vagrant", "box", "remove", "foo")
    result = execute("vagrant", "box", "list")
    result.should succeed
    result.stdout.should match_output(:no_boxes)
  end

  it "can repackage a box" do
    require_box("default")

    original_size = File.size(box_path("default"))
    logger.debug("Original package size: #{original_size}")

    # Add the box, repackage it, and verify that a package.box is
    # dumped of relatively similar size.
    execute("vagrant", "box", "add", "foo", box_path("default"))
    execute("vagrant", "box", "repackage", "foo")

    # By default, repackage should dump into package.box into the CWD
    repackaged_file = environment.workdir.join("package.box")
    repackaged_file.file?.should be, "package.box should exist in cwd of environment"

    # Compare the sizes
    repackaged_size = repackaged_file.size
    logger.debug("Repackaged size: #{repackaged_size}")
    size_diff = (repackaged_size - original_size).abs
    size_diff.should be < 1000, "Sizes should be very similar"
  end
end
