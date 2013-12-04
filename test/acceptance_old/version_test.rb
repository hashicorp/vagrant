require File.expand_path("../base", __FILE__)

describe "vagrant version" do
  include_context "acceptance"

  it "prints the version when called with '-v'" do
    result = execute("vagrant", "-v")
    result.stdout.should match_output(:version, config.vagrant_version)
  end

  it "prints the version when called with '--version'" do
    result = execute("vagrant", "--version")
    result.stdout.should match_output(:version, config.vagrant_version)
  end
end
