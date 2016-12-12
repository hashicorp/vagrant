require "pathname"
require "tmpdir"

require File.expand_path("../../base", __FILE__)

require "vagrant/util/platform"

describe Vagrant::Machine do
  include_context "unit"

  let(:name)     { "foo" }
  let(:provider) { new_provider_mock }
  let(:provider_cls) do
    obj = double("provider_cls")
    obj.stub(new: provider)
    obj
  end
  let(:provider_config) { Object.new }
  let(:provider_name) { :test }
  let(:provider_options) { {} }
  let(:base)     { false }
  let(:box) do
    double("box").tap do |b|
      b.stub(name: "foo")
      b.stub(provider: :dummy)
      b.stub(version: "1.0")
    end
  end

  let(:config)   { env.vagrantfile.config }
  let(:data_dir) { Pathname.new(Dir.mktmpdir("vagrant-machine-data-dir")) }
  let(:env)      do
    # We need to create a Vagrantfile so that this test environment
    # has a proper root path
    test_env.vagrantfile("")

    # Create the Vagrant::Environment instance
    test_env.create_vagrant_env
  end

  let(:test_env) { isolated_environment }

  let(:instance) { new_instance }

  after do
    FileUtils.rm_rf(data_dir) if data_dir
  end

  subject { instance }

  def new_provider_mock
    double("provider").tap do |obj|
      obj.stub(_initialize: nil)
      obj.stub(machine_id_changed: nil)
      allow(obj).to receive(:state).and_return(Vagrant::MachineState.new(
        :created, "", ""))
    end
  end

  # Returns a new instance with the test data
  def new_instance
    described_class.new(name, provider_name, provider_cls, provider_config,
                        provider_options, config, data_dir, box,
                        env, env.vagrantfile, base)
  end

  describe "initialization" do
    it "should set the ID to nil if the state is not created" do
      subject.id = "foo"

      allow(provider).to receive(:state).and_return(Vagrant::MachineState.new(
        Vagrant::MachineState::NOT_CREATED_ID, "short", "long"))

      subject = new_instance
      expect(subject.state.id).to eq(Vagrant::MachineState::NOT_CREATED_ID)
      expect(subject.id).to be_nil
    end

    describe "as a base" do
      let(:base) { true}

      it "should not insert key" do
        subject = new_instance
        expect(subject.config.ssh.insert_key).to be_false
      end
    end

    describe "communicator loading" do
      it "doesn't eager load SSH" do
        config.vm.communicator = :ssh

        klass = Vagrant.plugin("2").manager.communicators[:ssh]
        expect(klass).to_not receive(:new)

        subject
      end

      it "eager loads WinRM" do
        config.vm.communicator = :winrm

        klass    = Vagrant.plugin("2").manager.communicators[:winrm]
        instance = double("instance")
        expect(klass).to receive(:new).and_return(instance)

        subject
      end
    end

    describe "provider initialization" do
      # This is a helper that generates a test for provider initialization.
      # This is a separate helper method because it takes a block that can
      # be used to have additional tests on the received machine.
      #
      # @yield [machine] Yields the machine that the provider initialization
      #   method received so you can run additional tests on it.
      def provider_init_test(instance=nil)
        received_machine = nil

        if !instance
          instance = new_provider_mock
        end

        provider_cls = double("provider_cls")
        expect(provider_cls).to receive(:new) { |machine|
          # Store this for later so we can verify that it is the
          # one we expected to receive.
          received_machine = machine

          # Sanity check
          expect(machine).to be

          # Yield our machine if we want to do additional tests
          yield machine if block_given?
          true
        }.and_return(instance)

        # Initialize a new machine and verify that we properly receive
        # the machine we expect.
        instance = described_class.new(name, provider_name, provider_cls, provider_config,
                                       provider_options, config, data_dir, box,
                                       env, env.vagrantfile)
        expect(received_machine).to eql(instance)
      end

      it "should initialize with the machine object" do
        # Just run the blank test
        provider_init_test
      end

      it "should have the machine name setup" do
        provider_init_test do |machine|
          expect(machine.name).to eq(name)
        end
      end

      it "should have the machine configuration" do
        provider_init_test do |machine|
          expect(machine.config).to eql(config)
        end
      end

      it "should have the box" do
        provider_init_test do |machine|
          expect(machine.box).to eql(box)
        end
      end

      it "should have the environment" do
        provider_init_test do |machine|
          expect(machine.env).to eql(env)
        end
      end

      it "should have the vagrantfile" do
        provider_init_test do |machine|
          expect(machine.vagrantfile).to equal(env.vagrantfile)
        end
      end

      it "should have access to the ID" do
        # Stub this because #id= calls it.
        allow(provider).to receive(:machine_id_changed)

        # Set the ID on the previous instance so that it is persisted
        instance.id = "foo"

        provider_init_test do |machine|
          expect(machine.id).to eq("foo")
        end
      end

      it "should NOT have access to the provider" do
        provider_init_test do |machine|
          expect(machine.provider).to be_nil
        end
      end

      it "should initialize the capabilities" do
        instance = new_provider_mock
        expect(instance).to receive(:_initialize).with { |p, m|
          expect(p).to eq(provider_name)
          expect(m.name).to eq(name)
          true
        }

        provider_init_test(instance)
      end
    end
  end

  describe "attributes" do
    describe '#name' do
      subject { super().name }
      it             { should eq(name) }
    end

    describe '#config' do
      subject { super().config }
      it           { should eql(config) }
    end

    describe '#box' do
      subject { super().box }
      it              { should eql(box) }
    end

    describe '#env' do
      subject { super().env }
      it              { should eql(env) }
    end

    describe '#provider' do
      subject { super().provider }
      it         { should eql(provider) }
    end

    describe '#provider_config' do
      subject { super().provider_config }
      it  { should eql(provider_config) }
    end

    describe '#provider_options' do
      subject { super().provider_options }
      it { should eq(provider_options) }
    end
  end

  describe "#action" do
    it "should be able to run an action that exists" do
      action_name = :up
      called      = false
      callable    = lambda { |_env| called = true }

      expect(provider).to receive(:action).with(action_name).and_return(callable)
      instance.action(:up)
      expect(called).to be
    end

    it "should provide the machine in the environment" do
      action_name = :up
      machine     = nil
      callable    = lambda { |env| machine = env[:machine] }

      allow(provider).to receive(:action).with(action_name).and_return(callable)
      instance.action(:up)

      expect(machine).to eql(instance)
    end

    it "should pass any extra options to the environment" do
      action_name = :up
      foo         = nil
      callable    = lambda { |env| foo = env[:foo] }

      allow(provider).to receive(:action).with(action_name).and_return(callable)
      instance.action(:up, foo: :bar)

      expect(foo).to eq(:bar)
    end

    it "should pass any extra options to the environment as strings" do
      action_name = :up
      foo         = nil
      callable    = lambda { |env| foo = env["foo"] }

      allow(provider).to receive(:action).with(action_name).and_return(callable)
      instance.action(:up, "foo" => :bar)

      expect(foo).to eq(:bar)
    end

    it "should return the environment as a result" do
      action_name = :up
      callable    = lambda { |env| env[:result] = "FOO" }

      allow(provider).to receive(:action).with(action_name).and_return(callable)
      result = instance.action(action_name)

      expect(result[:result]).to eq("FOO")
    end

    it "should raise an exception if the action is not implemented" do
      action_name = :up

      allow(provider).to receive(:action).with(action_name).and_return(nil)

      expect { instance.action(action_name) }.
        to raise_error(Vagrant::Errors::UnimplementedProviderAction)
    end
  end

  describe "#action_raw" do
    let(:callable) {lambda { |e|
      e[:called] = true
      @env = e
    }}

    before do
      @env = {}
    end

    it "should run the callable with the proper env" do
      subject.action_raw(:foo, callable)

      expect(@env[:called]).to be_true
      expect(@env[:action_name]).to eq(:machine_action_foo)
      expect(@env[:machine]).to equal(subject)
      expect(@env[:machine_action]).to eq(:foo)
      expect(@env[:ui]).to equal(subject.ui)
    end

    it "should return the environment as a result" do
      result = subject.action_raw(:foo, callable)
      expect(result).to equal(@env)
    end

    it "should merge in any extra env" do
      subject.action_raw(:bar, callable, foo: :bar)

      expect(@env[:called]).to be_true
      expect(@env[:foo]).to eq(:bar)
    end
  end

  describe "#communicate" do
    it "should return the SSH communicator by default" do
      expect(subject.communicate).
        to be_kind_of(VagrantPlugins::CommunicatorSSH::Communicator)
    end

    it "should return the specified communicator if given" do
      subject.config.vm.communicator = :winrm
      expect(subject.communicate).
        to be_kind_of(VagrantPlugins::CommunicatorWinRM::Communicator)
    end

    it "should memoize the result" do
      obj = subject.communicate
      expect(subject.communicate).to equal(obj)
    end

    it "raises an exception if an invalid communicator is given" do
      subject.config.vm.communicator = :foo
      expect { subject.communicate }.
        to raise_error(Vagrant::Errors::CommunicatorNotFound)
    end
  end

  describe "guest implementation" do
    let(:communicator) do
      result = double("communicator")
      allow(result).to receive(:ready?).and_return(true)
      allow(result).to receive(:test).and_return(false)
      result
    end

    before(:each) do
      test_guest = Class.new(Vagrant.plugin("2", :guest)) do
        def detect?(machine)
          true
        end
      end

      register_plugin do |p|
        p.guest(:test) { test_guest }
      end

      allow(instance).to receive(:communicate).and_return(communicator)
    end

    it "should raise an exception if communication is not ready" do
      expect(communicator).to receive(:ready?).and_return(false)

      expect { instance.guest }.
        to raise_error(Vagrant::Errors::MachineGuestNotReady)
    end

    it "should return the configured guest" do
      result = instance.guest
      expect(result).to be_kind_of(Vagrant::Guest)
      expect(result).to be_ready
      expect(result.capability_host_chain[0][0]).to eql(:test)
    end
  end

  describe "setting the ID" do
    before(:each) do
      allow(provider).to receive(:machine_id_changed)
    end

    it "should not have an ID by default" do
      expect(instance.id).to be_nil
    end

    it "should set an ID" do
      instance.id = "bar"
      expect(instance.id).to eq("bar")
    end

    it "should notify the machine that the ID changed" do
      expect(provider).to receive(:machine_id_changed).once

      instance.id = "bar"
    end

    it "should persist the ID" do
      instance.id = "foo"
      expect(new_instance.id).to eq("foo")
    end

    it "should delete the ID" do
      instance.id = "foo"

      second = new_instance
      expect(second.id).to eq("foo")
      second.id = nil
      expect(second.id).to be_nil

      third = new_instance
      expect(third.id).to be_nil
    end

    it "should set the UID that created the machine" do
      instance.id = "foo"

      second = new_instance
      expect(second.uid).to eq(Process.uid.to_s)
    end

    it "should delete the UID when the id is nil" do
      instance.id = "foo"
      instance.id = nil

      second = new_instance
      expect(second.uid).to be_nil
    end
  end

  describe "#index_uuid" do
    before(:each) do
      allow(provider).to receive(:machine_id_changed)
    end

    it "should not have an index UUID by default" do
      expect(subject.index_uuid).to be_nil
    end

    it "is set one when setting an ID" do
      # Stub the message we want
      allow(provider).to receive(:state).and_return(Vagrant::MachineState.new(
        :preparing, "preparing", "preparing"))

      # Setup the box information
      box = double("box")
      box.stub(name: "foo")
      box.stub(provider: :bar)
      box.stub(version: "1.2.3")
      subject.box = box

      subject.id = "foo"

      uuid = subject.index_uuid
      expect(uuid).to_not be_nil
      expect(new_instance.index_uuid).to eq(uuid)

      # Test the entry itself
      entry = env.machine_index.get(uuid)
      expect(entry.name).to eq(subject.name)
      expect(entry.provider).to eq(subject.provider_name.to_s)
      expect(entry.state).to eq("preparing")
      expect(entry.vagrantfile_path).to eq(env.root_path)
      expect(entry.vagrantfile_name).to eq(env.vagrantfile_name)
      expect(entry.extra_data["box"]).to eq({
        "name"     => box.name,
        "provider" => box.provider.to_s,
        "version"  => box.version,
      })
      env.machine_index.release(entry)
    end

    it "deletes the UUID when setting to nil" do
      subject.id = "foo"
      uuid = subject.index_uuid

      subject.id = nil
      expect(subject.index_uuid).to be_nil
      expect(env.machine_index.get(uuid)).to be_nil
    end
  end

  describe "#reload" do
    before do
      allow(provider).to receive(:machine_id_changed)
      subject.id = "foo"
    end

    it "should read the ID" do
      expect(provider).to_not receive(:machine_id_changed)

      subject.reload

      expect(subject.id).to eq("foo")
    end

    it "should read the updated ID" do
      new_instance.id = "bar"

      expect(provider).to receive(:machine_id_changed)

      subject.reload

      expect(subject.id).to eq("bar")
    end
  end

  describe "#ssh_info" do

    describe "with the provider returning nil" do
      it "should return nil if the provider returns nil" do
        expect(provider).to receive(:ssh_info).and_return(nil)
        expect(instance.ssh_info).to be_nil
      end
    end

    describe "with the provider returning data" do
      let(:provider_ssh_info) { {} }
      let(:ssh_klass) { Vagrant::Util::SSH }

      before(:each) do
        allow(provider).to receive(:ssh_info).and_return(provider_ssh_info)
        # Stub the check_key_permissions method so that even if we test incorrectly,
        # no side effects actually happen.
        allow(ssh_klass).to receive(:check_key_permissions)
      end

      [:host, :port, :username].each do |type|
        it "should return the provider data if not configured in Vagrantfile" do
          provider_ssh_info[type] = "foo"
          instance.config.ssh.send("#{type}=", nil)

          expect(instance.ssh_info[type]).to eq("foo")
        end

        it "should return the Vagrantfile value if provider data not given" do
          provider_ssh_info[type] = nil
          instance.config.ssh.send("#{type}=", "bar")

          expect(instance.ssh_info[type]).to eq("bar")
        end

        it "should use the default if no override and no provider" do
          provider_ssh_info[type] = nil
          instance.config.ssh.send("#{type}=", nil)
          instance.config.ssh.default.send("#{type}=", "foo")

          expect(instance.ssh_info[type]).to eq("foo")
        end

        it "should use the override if set even with a provider" do
          provider_ssh_info[type] = "baz"
          instance.config.ssh.send("#{type}=", "bar")
          instance.config.ssh.default.send("#{type}=", "foo")

          expect(instance.ssh_info[type]).to eq("bar")
        end
      end

      it "should set the configured forward agent settings" do
        provider_ssh_info[:forward_agent] = true
        instance.config.ssh.forward_agent = false

        expect(instance.ssh_info[:forward_agent]).to eq(false)
      end

      it "should set the configured forward X11 settings" do
        provider_ssh_info[:forward_x11] = true
        instance.config.ssh.forward_x11 = false

        expect(instance.ssh_info[:forward_x11]).to eq(false)
      end

      it "should return the provider private key if given" do
        provider_ssh_info[:private_key_path] = "/foo"

        expect(instance.ssh_info[:private_key_path]).to eq([File.expand_path("/foo", env.root_path)])
      end

      it "should return the configured SSH key path if set" do
        provider_ssh_info[:private_key_path] = nil
        instance.config.ssh.private_key_path = "/bar"

        expect(instance.ssh_info[:private_key_path]).to eq([File.expand_path("/bar", env.root_path)])
      end

      it "should return the array of SSH keys if set" do
        provider_ssh_info[:private_key_path] = nil
        instance.config.ssh.private_key_path = ["/foo", "/bar"]

        expect(instance.ssh_info[:private_key_path]).to eq([
          File.expand_path("/foo", env.root_path),
          File.expand_path("/bar", env.root_path),
        ])
      end

      it "should check and try to fix the permissions of the default private key file" do
        provider_ssh_info[:private_key_path] = nil
        instance.config.ssh.private_key_path = nil

        expect(ssh_klass).to receive(:check_key_permissions).once.with(Pathname.new(instance.env.default_private_key_path.to_s))
        instance.ssh_info
      end

      it "should check and try to fix the permissions of given private key files" do
        provider_ssh_info[:private_key_path] = nil
        # Use __FILE__ to provide an existing file
        instance.config.ssh.private_key_path = [File.expand_path(__FILE__), File.expand_path(__FILE__)]

        expect(ssh_klass).to receive(:check_key_permissions).twice.with(Pathname.new(File.expand_path(__FILE__)))
        instance.ssh_info
      end

      it "should not check the permissions of a private key file that does not exist" do
        provider_ssh_info[:private_key_path] = "/foo"

        expect(ssh_klass).to_not receive(:check_key_permissions)
        instance.ssh_info
      end

      context "expanding path relative to the root path" do
        it "should with the provider key path" do
          provider_ssh_info[:private_key_path] = "~/foo"

          expect(instance.ssh_info[:private_key_path]).to eq(
            [File.expand_path("~/foo", env.root_path)]
          )
        end

        it "should with the config private key path" do
          provider_ssh_info[:private_key_path] = nil
          instance.config.ssh.private_key_path = "~/bar"

          expect(instance.ssh_info[:private_key_path]).to eq(
            [File.expand_path("~/bar", env.root_path)]
          )
        end
      end

      it "should return the default private key path if provider and config doesn't have one" do
        provider_ssh_info[:private_key_path] = nil
        instance.config.ssh.private_key_path = nil

        expect(instance.ssh_info[:private_key_path]).to eq(
          [instance.env.default_private_key_path.to_s]
        )
      end

      it "should not set any default private keys if a password is specified" do
        provider_ssh_info[:private_key_path] = nil
        instance.config.ssh.private_key_path = nil
        instance.config.ssh.password = ""

        expect(instance.ssh_info[:private_key_path]).to be_empty
        expect(instance.ssh_info[:password]).to eql("")
      end

      it "should return the private key in the data dir above all else" do
        provider_ssh_info[:private_key_path] = nil
        instance.config.ssh.private_key_path = nil
        instance.config.ssh.password = ""

        instance.data_dir.join("private_key").open("w+") do |f|
          f.write("hey")
        end

        expect(instance.ssh_info[:private_key_path]).to eql(
          [instance.data_dir.join("private_key").to_s])
        expect(instance.ssh_info[:password]).to eql("")
      end

      it "should return the private key in the Vagrantfile if the data dir exists" do
        path = "/foo"
        path = "C:/foo" if Vagrant::Util::Platform.windows?

        provider_ssh_info[:private_key_path] = nil
        instance.config.ssh.private_key_path = path

        instance.data_dir.join("private_key").open("w+") do |f|
          f.write("hey")
        end

        expect(instance.ssh_info[:private_key_path]).to eql([path])
      end

      context "with no data dir" do
        let(:base)     { true }
        let(:data_dir) { nil }

        it "returns nil as the private key path" do
          provider_ssh_info[:private_key_path] = nil
          instance.config.ssh.private_key_path = nil
          instance.config.ssh.password = ""

          expect(instance.ssh_info[:private_key_path]).to be_empty
          expect(instance.ssh_info[:password]).to eql("")
        end
      end

      context "with custom ssh_info" do
        it "keys_only should be default" do
          expect(instance.ssh_info[:keys_only]).to be_true
        end
        it "paranoid should be default" do
          expect(instance.ssh_info[:paranoid]).to be_false
        end
        it "keys_only should be overridden" do
          instance.config.ssh.keys_only = false
          expect(instance.ssh_info[:keys_only]).to be_false
        end
        it "paranoid should be overridden" do
          instance.config.ssh.paranoid = true
          expect(instance.ssh_info[:paranoid]).to be_true
        end
      end
    end
  end

  describe "#state" do
    it "should query state from the provider" do
      state = Vagrant::MachineState.new(:id, "short", "long")

      allow(provider).to receive(:state).and_return(state)
      expect(instance.state.id).to eq(:id)
    end

    it "should raise an exception if a MachineState is not returned" do
      expect(provider).to receive(:state).and_return(:old_school)
      expect { instance.state }.
        to raise_error(Vagrant::Errors::MachineStateInvalid)
    end

    it "should save the state with the index" do
      allow(provider).to receive(:machine_id_changed)
      subject.id = "foo"

      state = Vagrant::MachineState.new(:id, "short", "long")
      expect(provider).to receive(:state).and_return(state)

      subject.state

      entry = env.machine_index.get(subject.index_uuid)
      expect(entry).to_not be_nil
      expect(entry.state).to eq("short")
      env.machine_index.release(entry)
    end
  end

  describe "#with_ui" do
    it "temporarily changes the UI" do
      ui = Object.new
      changed_ui = nil

      subject.with_ui(ui) do
        changed_ui = subject.ui
      end

      expect(changed_ui).to equal(ui)
      expect(subject.ui).to_not equal(ui)
    end
  end
end
