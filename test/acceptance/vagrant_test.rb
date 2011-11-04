require File.expand_path("../base", __FILE__)

# NOTE: Many tests in this test suite require the `expect`
# tool to be installed, because `expect` will launch with a
# PTY.
class VagrantTestColorOutput < AcceptanceTest
  def has_expect?
    `which expect`
    $?.success?
  end

  # This is a helper to check for a color in some text.
  # This will return `nil` if no color is found, any other
  # truthy value otherwise.
  def has_color?(text)
    text.index("\e[31m")
  end

  should "output color if there is a TTY" do
    skip("Test requires `expect`") if !has_expect?

    @environment.workdir.join("color.exp").open("w+") do |f|
      f.puts(<<-SCRIPT)
spawn #{@environment.replace_command("vagrant")} status
expect default {}
SCRIPT
    end

    result = execute("expect", "color.exp")
    assert(has_color?(result.stdout.read), "output should contain color")
  end

  should "not output color if there is a TTY but --no-color is present" do
    skip("Test requires `expect`") if !has_expect?

    @environment.workdir.join("color.exp").open("w+") do |f|
      f.puts(<<-SCRIPT)
spawn #{@environment.replace_command("vagrant")} status --no-color
expect default {}
SCRIPT
    end

    result = execute("expect", "color.exp")
    assert(!has_color?(result.stdout.read), "output should not contain color")
  end

  should "not output color in the absense of a TTY" do
    # This should always output an error, which on a TTY would
    # output color. We check that this doesn't output color.
    # If `vagrant status` itself is broken, another acceptance test
    # should catch that. We just assume it works here.
    result = execute("vagrant", "status")
    assert(!has_color?(result.stdout.read), "output should not contain color")
  end
end
