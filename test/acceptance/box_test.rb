require "digest/sha1"

require File.expand_path("../base", __FILE__)

class BoxTest < AcceptanceTest
  def require_box(name)
    if !config.boxes.has_key?(name) || !File.file?(config.boxes[name])
      raise ArgumentError, "The configuration should specify a '#{name}' box."
    end
  end

  should "have no boxes by default" do
    result = execute("vagrant", "box", "list")
    assert result.stdout.read =~ /There are no installed boxes!/
  end

  should "add a box from a file" do
    require_box("default")

    # Add the box, which we expect to succeed
    results = execute("vagrant", "box", "add", "foo", config.boxes["default"])
    assert(results.success?, "Box add should succeed.")

    # Verify that the box now shows up in the list of available boxes
    results = execute("vagrant", "box", "list")
    assert(results.stdout.read =~ /^foo$/, "Box should exist after it is added")
  end

  should "give an error if the file doesn't exist" do
    results = execute("vagrant", "box", "add", "foo", "/tmp/nope/nope/nope/nonono.box")
    assert(!results.success?, "Box add should fail.")
    assert(results.stdout.read =~ /^The specified path to a file doesn't exist.$/,
           "This should show an error message about the file not existing.")
  end

  should "give an error if the file is not a valid box" do
    invalid = @environment.workdir.join("nope.txt")
    invalid.open("w+") do |f|
      f.write("INVALID!")
    end

    results = execute("vagrant", "box", "add", "foo", invalid.to_s)
    assert(!results.success?, "Box add should fail.")
    assert(results.stdout.read =~ /^The box file you're attempting to add is invalid./,
           "should show an error message")
  end

  should "add a box from an HTTP server" do
    # TODO: Spin up an HTTP server to serve a file, add and test.
    skip("Need to setup HTTP server functionality")
  end

  should "remove a box" do
    require_box("default")

    # Add the box, remove the box, then verify that the box no longer
    # shows up in the list of available boxes.
    execute("vagrant", "box", "add", "foo", config.boxes["default"])
    execute("vagrant", "box", "remove", "foo")
    results = execute("vagrant", "box", "list")
    assert(results.success?, "box list should succeed")
    assert(results.stdout.read =~ /^There are no installed boxes!/,
           "box list should be empty")
  end

  should "repackage a box" do
    require_box("default")

    original_size = File.size(config.boxes["default"])
    @logger.debug("Original package size: #{original_size}")

    # Add the box, repackage it, and verify that a package.box is
    # dumped of relatively similar size.
    execute("vagrant", "box", "add", "foo", config.boxes["default"])
    execute("vagrant", "box", "repackage", "foo")

    # By default, repackage should dump into package.box into the CWD
    repackaged_file = @environment.workdir.join("package.box")
    assert(repackaged_file.file?, "package.box should exist in cwd of environment")

    # Compare the sizes
    repackaged_size = repackaged_file.size
    @logger.debug("Repackaged size: #{repackaged_size}")
    size_diff = (repackaged_size - original_size).abs
    assert(size_diff < 1000, "Sizes should be very similar")
  end
end
