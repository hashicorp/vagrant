require File.expand_path("../base", __FILE__)

class BoxTest < AcceptanceTest
  should "have no boxes by default" do
    result = execute("vagrant", "box", "list")
    assert result.stdout.read =~ /There are no installed boxes!/
  end

  should "add a box from a file" do
    if !config.boxes.has_key?("default") || !File.file?(config.boxes["default"])
      raise ArgumentError, "The configuration should specify a 'default' box."
    end

    # Add the box, which we expect to succeed
    results = execute("vagrant", "box", "add", "foo", config.boxes["default"])
    assert(results.success?, "Box add should succeed.")

    # Verify that the box now shows up in the list of available boxes
    results = execute("vagrant", "box", "list")
    assert(results.stdout.read =~ /^foo$/, "Box should exist after it is added")
  end

  should "give a helpful error message if the file doesn't exist" do
    # Add a box which doesn't exist
    results = execute("vagrant", "box", "add", "foo", "/tmp/nope/nope/nope/nonono.box")
    assert(!results.success?, "Box add should fail.")
    assert(results.stdout.read =~ /^The specified path to a file doesn't exist.$/,
           "This should show an error message about the file not existing.")
  end

  should "add a box from an HTTP server" do
    # TODO: Spin up an HTTP server to serve a file, add and test.
    skip("Need to setup HTTP server functionality")
  end
end
