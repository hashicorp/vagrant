require File.expand_path("../base", __FILE__)

# NOTE: Many tests in this test suite require the `expect`
# tool to be installed, because `expect` will launch with a
# PTY.
class VagrantTestColorOutput < AcceptanceTest
  def has_expect?
    `which expect`
    $?.success?
  end

  should "output color if there is a TTY" do
    skip("Test requires `expect`") if !has_expect?

    @environment.workdir.join("color.exp").open("w+") do |f|
      f.write(<<-SCRIPT)
catch {spawn vagrant status} reason
expect {
    "\e[31m" { exit }
    default { exit 1 }
}
SCRIPT
    end

    results = execute("expect", "color.exp")
    assert_equal(0, results.exit_status)
  end

  should "not output color if there is a TTY but --no-color is present" do
    skip("Test requires `expect`") if !has_expect?

    @environment.workdir.join("color.exp").open("w+") do |f|
      f.write(<<-SCRIPT)
catch {spawn vagrant status --no-color} reason
expect {
    "\e[31m" { exit 1 }
    default { exit }
}
SCRIPT
    end

    results = execute("expect", "color.exp")
    assert_equal(0, results.exit_status)
  end

  should "not output color in the absense of a TTY" do
    # This should always output an error, which on a TTY would
    # output color. We check that this doesn't output color.
    # If `vagrant status` itself is broken, another acceptance test
    # should catch that. We just assume it works here.
    result = execute("vagrant", "status")
    assert(result.stdout.read !~ /\e\[31/, "output should not contain color")
  end
end
