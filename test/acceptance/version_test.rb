require File.expand_path("../base", __FILE__)

class VersionTest < AcceptanceTest
  should "print the version to stdout" do
    result = execute("vagrant", "version")
    assert(output(result.stdout).is_version?(config.vagrant_version),
           "output should be version")
  end

  should "print the version with '-v'" do
    result = execute("vagrant", "-v")
    assert(output(result.stdout).is_version?(config.vagrant_version),
           "output should be version")
  end

  should "print the version with '--version'" do
    result = execute("vagrant", "--version")
    assert(output(result.stdout).is_version?(config.vagrant_version),
           "output should be version")
  end
end
