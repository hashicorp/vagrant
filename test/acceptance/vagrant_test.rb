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
      f.puts(<<-SCRIPT)
spawn #{@environment.replace_command("vagrant")} status
expect default {}
SCRIPT
    end

    result = execute("expect", "color.exp")
    assert(result.stdout.read.index("\e[31m"), "output should contain color")
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
    assert(!result.stdout.read.index("\e[31m"), "output should not contain color")
  end

  should "not output color in the absense of a TTY" do
    # This should always output an error, which on a TTY would
    # output color. We check that this doesn't output color.
    # If `vagrant status` itself is broken, another acceptance test
    # should catch that. We just assume it works here.
    result = execute("vagrant", "status")
    assert(!result.stdout.read.index("\e[31m"), "output should not contain color")
  end
end
