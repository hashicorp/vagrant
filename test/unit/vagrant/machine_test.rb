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
  let(:env)      do
    # We need to create a Vagrantfile so that this test environment
    # has a proper root path
    test_env.vagrantfile("")

    # Create the Vagrant::Environment instance
    test_env.create_vagrant_env
  end

  let(:test_env) { isolated_environment }

  let(:instance) { new_instance }

  # Returns a new instance with the test data
  def new_instance
    described_class.new(name, provider_cls, config, box, env)
  end

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
        machine.env.should eql(env)
      end

      instance = described_class.new(name, provider_cls, config, box, env)
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
      instance.env.should eql(env)
    end
  end

  describe "actions" do
    it "should be able to run an action that exists" do
      action_name = :up
      called      = false
      callable    = lambda { |_env| called = true }

      provider.should_receive(:action).with(action_name).and_return(callable)
      instance.action(:up)
      called.should be
    end

    it "should provide the machine in the environment" do
      action_name = :up
      machine     = nil
      callable    = lambda { |env| machine = env[:machine] }

      provider.stub(:action).with(action_name).and_return(callable)
      instance.action(:up)

      machine.should eql(instance)
    end

    it "should raise an exception if the action is not implemented" do
      action_name = :up

      provider.stub(:action).with(action_name).and_return(nil)

      expect { instance.action(action_name) }.
        to raise_error(Vagrant::Errors::UnimplementedProviderAction)
    end
  end

  describe "setting the ID" do
    it "should not have an ID by default" do
      instance.id.should be_nil
    end

    it "should set an ID" do
      instance.id = "bar"
      instance.id.should == "bar"
    end

    it "should persist the ID" do
      instance.id = "foo"
      new_instance.id.should == "foo"
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
