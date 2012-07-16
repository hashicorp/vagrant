require File.expand_path("../../base", __FILE__)

describe Vagrant::Machine do
  include_context "unit"

  let(:name)     { "foo" }
  let(:provider) { double("provider") }
  let(:provider_cls) do
    obj = double("provider_cls")
    obj.stub(:new => provider)
    obj
  end
  let(:box)      { Object.new }
  let(:config)   { Object.new }
  let(:environment) { isolated_environment }

  let(:instance) { described_class.new(name, provider_cls, config, box, environment) }

  describe "initialization" do
    it "should initialize the provider with the machine object" do
      received_machine = nil

      provider_cls = double("provider_cls")
      provider_cls.should_receive(:new) do |machine|
        # Store this for later so we can verify that it is the
        # one we expected to receive.
        received_machine = machine

        # Verify the machine is fully ready to be used.
        machine.name.should == name
        machine.config.should eql(config)
        machine.box.should eql(box)
        machine.env.should eql(environment)
      end

      instance = described_class.new(name, provider_cls, config, box, environment)
      received_machine.should eql(instance)
    end
  end

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

  describe "state" do
    it "should query state from the provider" do
      state = :running

      provider.should_receive(:state).and_return(state)
      instance.state.should == state
    end
  end
end
