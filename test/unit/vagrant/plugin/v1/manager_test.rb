require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Plugin::V1::Manager do
  include_context "unit"

  let(:instance) { described_class.new }

  def plugin
    p = Class.new(Vagrant.plugin("1"))
    yield p
    p
  end

  it "should enumerate registered configuration classes" do
    pA = plugin do |p|
      p.config("foo") { "bar" }
    end

    instance.register(pA)

    instance.config.length.should == 1
    instance.config[:foo].should == "bar"
  end
end
