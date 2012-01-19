require File.expand_path("../../../base", __FILE__)

describe Vagrant::Config::SSHConfig do
  include_context "unit"

  [:forward_agent, :forward_x11].each do |bool_setting|
    it "merges boolean #{bool_setting} properly" do
      a = described_class.new
      a.send("#{bool_setting}=", true)

      b = described_class.new

      c = a.merge(b)
      c.send(bool_setting).should be
    end
  end
end
