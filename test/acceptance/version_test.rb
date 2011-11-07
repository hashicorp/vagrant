require File.expand_path("../base", __FILE__)

describe "vagrant version" do
  include_context "acceptance"

  it "prints the version to stdout" do
    result = execute("vagrant", "version")
    assert(output(result.stdout).is_version?(config.vagrant_version),
           "output should be version")
  end

  it "prints the version when called with '-v'" do
    result = execute("vagrant", "-v")
    assert(output(result.stdout).is_version?(config.vagrant_version),
           "output should be version")
  end

  it "prints the version when called with '--version'" do
    result = execute("vagrant", "--version")
    assert(output(result.stdout).is_version?(config.vagrant_version),
           "output should be version")
  end
end
