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
    describe "provider initialization" do
      # This is a helper that generates a test for provider intialization.
      # This is a separate helper method because it takes a block that can
      # be used to have additional tests on the received machine.
      #
      # @yield [machine] Yields the machine that the provider initialization
      #   method received so you can run additional tests on it.
      def provider_init_test
        received_machine = nil

        provider_cls = double("provider_cls")
        provider_cls.should_receive(:new) do |machine|
          # Store this for later so we can verify that it is the
          # one we expected to receive.
          received_machine = machine

          # Sanity check
          machine.should be

          # Yield our machine if we want to do additional tests
          yield machine if block_given?
        end

        # Initialize a new machine and verify that we properly receive
        # the machine we expect.
        instance = described_class.new(name, provider_cls, config, box, env)
        received_machine.should eql(instance)
      end

      it "should initialize with the machine object" do
        # Just run the blank test
        provider_init_test
      end

      it "should have the machine name setup" do
        provider_init_test do |machine|
          machine.name.should == name
        end
      end

      it "should have the machine configuration" do
        provider_init_test do |machine|
          machine.config.should eql(config)
        end
      end

      it "should have the box" do
        provider_init_test do |machine|
          machine.box.should eql(box)
        end
      end

      it "should have the environment" do
        provider_init_test do |machine|
          machine.env.should eql(env)
        end
      end

      it "should have access to the ID" do
        instance.id = "foo"

        provider_init_test do |machine|
          machine.id.should == "foo"
        end
      end

      it "should NOT have access to the provider" do
        provider_init_test do |machine|
          machine.provider.should be_nil
        end
      end
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

    it "should provide access to the provider" do
      instance.provider.should eql(provider)
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
