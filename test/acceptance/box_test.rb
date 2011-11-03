require File.expand_path("../base", __FILE__)

class BoxTest < AcceptanceTest
  should "have no boxes by default" do
    result = execute("vagrant", "box", "list")
    assert result.stdout.read =~ /There are no installed boxes!/
  end
end
