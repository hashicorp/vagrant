require File.expand_path("../../base", __FILE__)

describe Vagrant::Machine do
  include_context "unit"

  let(:name)     { "foo" }
  let(:provider) { Object.new }
  let(:box)      { Object.new }
  let(:config)   { Object.new }
  let(:environment) { isolated_environment }

  let(:instance) { described_class.new(name, provider, config, box, environment) }

  describe "attributes" do
    it "should provide access to the name" do
      instance.name.should == name
    end

    it "should provide access to the configuration" do
      instance.config.should eql(config)
    end

    it "should provide access to the box" do
      instance.box.should eql(box)
    end

    it "should provide access to the environment" do
      instance.env.should eql(environment)
    end
  end
end
