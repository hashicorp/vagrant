require File.expand_path("../base", __FILE__)

class VersionTest < AcceptanceTest
  should "print the version to stdout" do
    result = execute("vagrant", "version")
    assert(result.stdout =~ /^Vagrant version #{config.vagrant_version}$/,
           "output should contain Vagrant version")
  end

  should "print the version with '-v'" do
    result = execute("vagrant", "-v")
    assert(result.stdout =~ /^Vagrant version #{config.vagrant_version}$/,
           "output should contain Vagrant version")
  end

  should "print the version with '--version'" do
    result = execute("vagrant", "--version")
    assert(result.stdout =~ /^Vagrant version #{config.vagrant_version}$/,
           "output should contain Vagrant version")
  end
end
