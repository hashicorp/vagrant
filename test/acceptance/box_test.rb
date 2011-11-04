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
end
