require File.expand_path("../base", __FILE__)

class VersionTest < AcceptanceTest
  should "print the version to stdout" do
    result = execute("vagrant", "version")
    assert_equal("Vagrant version #{config.vagrant_version}\n", result.stdout.read)
  end

  should "print the version with '-v'" do
    result = execute("vagrant", "-v")
    assert_equal("Vagrant version #{config.vagrant_version}\n", result.stdout.read)
  end

  should "print the version with '--version'" do
    result = execute("vagrant", "--version")
    assert_equal("Vagrant version #{config.vagrant_version}\n", result.stdout.read)
  end
end
