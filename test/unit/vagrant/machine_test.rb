require "pathname"

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
  let(:provider_config) { Object.new }
  let(:box)      { Object.new }
  let(:config)   { env.config_global }
  let(:data_dir) { Pathname.new(Tempdir.new.path) }
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
    described_class.new(name, provider_cls, provider_config,
                        config, data_dir, box, env)
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
        instance = described_class.new(name, provider_cls, provider_config,
                                       config, data_dir, box, env)
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
        # Stub this because #id= calls it.
        provider.stub(:machine_id_changed)

        # Set the ID on the previous instance so that it is persisted
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

    it "should pass any extra options to the environment" do
      action_name = :up
      foo         = nil
      callable    = lambda { |env| foo = env[:foo] }

      provider.stub(:action).with(action_name).and_return(callable)
      instance.action(:up, :foo => :bar)

      foo.should == :bar
    end

    it "should return the environment as a result" do
      action_name = :up
      callable    = lambda { |env| env[:result] = "FOO" }

      provider.stub(:action).with(action_name).and_return(callable)
      result = instance.action(action_name)

      result[:result].should == "FOO"
    end

    it "should raise an exception if the action is not implemented" do
      action_name = :up

      provider.stub(:action).with(action_name).and_return(nil)

      expect { instance.action(action_name) }.
        to raise_error(Vagrant::Errors::UnimplementedProviderAction)
    end
  end

  describe "communicator" do
    it "should always return the SSH communicator" do
      instance.communicate.should be_kind_of(VagrantPlugins::CommunicatorSSH::Communicator)
    end

    it "should memoize the result" do
      obj = instance.communicate
      instance.communicate.should eql(obj)
    end
  end

  describe "guest implementation" do
    let(:communicator) do
      result = double("communicator")
      result.stub(:ready?).and_return(true)
      result
    end

    before(:each) do
      instance.stub(:communicate).and_return(communicator)
    end

    it "should raise an exception if communication is not ready" do
      communicator.should_receive(:ready?).and_return(false)

      expect { instance.guest }.
        to raise_error(Vagrant::Errors::MachineGuestNotReady)
    end

    it "should return the configured guest" do
      test_guest = Class.new(Vagrant.plugin("2", :guest))

      register_plugin do |p|
        p.guest(:test) { test_guest }
      end

      config.vm.guest = :test

      result = instance.guest
      result.should be_kind_of(test_guest)
    end

    it "should raise an exception if it can't find the configured guest" do
      config.vm.guest = :bad

      expect { instance.guest }.
        to raise_error(Vagrant::Errors::VMGuestError)
    end

    it "should distro dispatch to the most specific guest" do
      # Create the classes and dispatch the parent into the child
      guest_parent = Class.new(Vagrant.plugin("2", :guest)) do
        def distro_dispatch
          :child
        end
      end

      guest_child  = Class.new(Vagrant.plugin("2", :guest))

      # Register the classes
      register_plugin do |p|
        p.guest(:parent) { guest_parent }
        p.guest(:child)  { guest_child }
      end

      # Test that the result is the child
      config.vm.guest = :parent
      instance.guest.should be_kind_of(guest_child)
    end

    it "should protect against loops in the distro dispatch" do
      # Create the classes and dispatch the parent into the child
      guest_parent = Class.new(Vagrant.plugin("2", :guest)) do
        def distro_dispatch
          :parent
        end
      end

      # Register the classes
      register_plugin do |p|
        p.guest(:parent) { guest_parent }
      end

      # Test that the result is the child
      config.vm.guest = :parent
      instance.guest.should be_kind_of(guest_parent)
     end
  end

  describe "setting the ID" do
    before(:each) do
      provider.stub(:machine_id_changed)
    end

    it "should not have an ID by default" do
      instance.id.should be_nil
    end

    it "should set an ID" do
      instance.id = "bar"
      instance.id.should == "bar"
    end

    it "should notify the machine that the ID changed" do
      provider.should_receive(:machine_id_changed).once

      instance.id = "bar"
    end

    it "should persist the ID" do
      instance.id = "foo"
      new_instance.id.should == "foo"
    end

    it "should delete the ID" do
      instance.id = "foo"

      second = new_instance
      second.id.should == "foo"
      second.id = nil

      third = new_instance
      third.id.should be_nil
    end
  end

  describe "ssh info" do
    describe "with the provider returning nil" do
      it "should return nil if the provider returns nil" do
        provider.should_receive(:ssh_info).and_return(nil)
        instance.ssh_info.should be_nil
      end
    end

    describe "with the provider returning data" do
      let(:provider_ssh_info) { {} }

      before(:each) do
        provider.should_receive(:ssh_info).and_return(provider_ssh_info)
      end

      [:host, :port, :username].each do |type|
        it "should return the provider data if not configured in Vagrantfile" do
          provider_ssh_info[type] = "foo"
          instance.config.ssh.send("#{type}=", nil)

          instance.ssh_info[type].should == "foo"
        end

        it "should return the Vagrantfile value over the provider data if given" do
          provider_ssh_info[type] = "foo"
          instance.config.ssh.send("#{type}=", "bar")

          instance.ssh_info[type].should == "bar"
        end
      end

      it "should set the configured forward agent settings" do
        provider_ssh_info[:forward_agent] = true
        instance.config.ssh.forward_agent = false

        instance.ssh_info[:forward_agent].should == false
      end

      it "should set the configured forward X11 settings" do
        provider_ssh_info[:forward_x11] = true
        instance.config.ssh.forward_x11 = false

        instance.ssh_info[:forward_x11].should == false
      end

      it "should return the provider private key if given" do
        provider_ssh_info[:private_key_path] = "foo"

        instance.ssh_info[:private_key_path].should == "foo"
      end

      it "should return the configured SSH key path if set" do
        provider_ssh_info[:private_key_path] = "foo"
        instance.config.ssh.private_key_path = "bar"

        instance.ssh_info[:private_key_path].should == "bar"
      end

      it "should return the default private key path if provider and config doesn't have one" do
        provider_ssh_info[:private_key_path] = nil
        instance.config.ssh.private_key_path = nil

        instance.ssh_info[:private_key_path].should == instance.env.default_private_key_path
      end
    end
  end

  describe "state" do
    it "should query state from the provider" do
      state = Vagrant::MachineState.new(:id, "short", "long")

      provider.should_receive(:state).and_return(state)
      instance.state.id.should == :id
    end

    it "should raise an exception if a MachineState is not returned" do
      provider.should_receive(:state).and_return(:old_school)
      expect { instance.state }.
        to raise_error(Vagrant::Errors::MachineStateInvalid)
    end
  end
end
