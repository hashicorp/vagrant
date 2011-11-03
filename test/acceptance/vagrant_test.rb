require File.expand_path("../base", __FILE__)

class VagrantTest < AcceptanceTest
  should "not output color in the absense of a TTY" do
    # This should always output an erorr, which on a TTY would
    # output color. We check that this doesn't output color.
    # If `vagrant status` itself is broken, another acceptance test
    # should catch that. We just assume it works here.
    result = execute("vagrant", "status")
    assert(result.stdout.read !~ /\e\[31/, "output should not contain color")
  end
end
