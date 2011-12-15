require File.expand_path("../../base", __FILE__)

describe "vagrant provisioning with chef solo" do
  include_context "acceptance"

  it "runs basic cookbooks" do
    pending "Setup chef infra for tests"
  end
end
