require_relative "../../base"

describe Vagrant::GoPlugin::ProviderPlugin do
  let(:client) { double("client") }

  describe Vagrant::GoPlugin::ProviderPlugin::Action do
    let(:described_class) { Class.new(Vagrant::GoPlugin::ProviderPlugin::Action) }

    it "should be a GRPCPlugin" do
      expect(described_class.ancestors).to include(Vagrant::GoPlugin::GRPCPlugin)
    end

    describe ".action_name" do
      it "should return nil when unset" do
        expect(described_class.action_name).to be_nil
      end

      it "should return defined action name when set" do
        described_class.action_name = "test_action"
        expect(described_class.action_name).to eq("test_action")
      end
    end

    describe ".action_name=" do
      it "should convert action name to string" do
        described_class.action_name = :test_action
        expect(described_class.action_name).to be_a(String)
      end

      it "should set the action name" do
        described_class.action_name = "test_action"
        expect(described_class.action_name).to eq("test_action")
      end

      it "should error if action name is already set" do
        described_class.action_name = "test_action"
        expect { described_class.action_name = "test_action" }.
          to raise_error(ArgumentError)
      end

      it "should freeze action name" do
        described_class.action_name = "test_action"
        expect(described_class.action_name).to be_frozen
      end
    end

    describe "#call" do
      let(:app) { double("app") }
      let(:env) { {"key1" => "value1", "key2" => "value2"} }
      let(:response_env) {
        {"key1" => "value1", "key2" => "value2"}
      }
      let(:response) { double("response", result: response_env.to_json) }

      let(:subject) {
        described_class.plugin_client = client
        described_class.new(app, {})
      }

      before do
        described_class.action_name = "test_action"
        allow(app).to receive(:call)
        allow(client).to receive(:run_action).and_return(response)
      end

      it "should call the next item in the middleware" do
        expect(app).to receive(:call)
        subject.call(env)
      end

      it "should call the client" do
        expect(client).to receive(:run_action).and_return(response)
        subject.call(env)
      end

      context "when new data is provided in result" do
        let(:response_env) { {"new_data" => "value"} }

        it "should include new data when calling next action" do
          expect(app).to receive(:call).
            with(hash_including("new_data" => "value", "key1" => "value1"))
          subject.call(env)
        end
      end
    end
  end

  describe Vagrant::GoPlugin::ProviderPlugin::Provider do
    let(:described_class) {
      Class.new(Vagrant::GoPlugin::ProviderPlugin::Provider).tap { |c|
        c.plugin_client = client
      }
    }
    let(:machine) { double("machine") }
    let(:subject) { described_class.new(machine) }

    it "should be a GRPCPlugin" do
      expect(described_class.ancestors).to include(Vagrant::GoPlugin::GRPCPlugin)
    end

    describe "#name" do
      let(:name) { double("name") }
      let(:response) { double("response", name: name) }

      before { allow(client).to receive(:name).and_return(response) }

      it "should request name from the client" do
        expect(client).to receive(:name).and_return(response)
        subject.name
      end

      it "should return the plugin name" do
        expect(subject.name).to eq(name)
      end

      it "should only call the client once" do
        expect(client).to receive(:name).once.and_return(response)
        subject.name
      end
    end

    describe "#action" do
      let(:action_name) { "test_action" }
      let(:response) { double("response", items: actions) }
      let(:actions) { ["self::TestAction"] }

      before do
        allow(client).to receive(:action).and_return(response)
      end

      it "should return a builder instance" do
        expect(subject.action(action_name)).to be_a(Vagrant::Action::Builder)
      end

      it "should call the plugin client" do
        expect(client).to receive(:action).
          with(instance_of(Vagrant::Proto::GenericAction)).
          and_return(response)
        subject.action(action_name)
      end

      it "should create a new custom action class" do
        builder = subject.action(action_name)
        action = builder.stack.first.first
        expect(action.ancestors).to include(Vagrant::GoPlugin::ProviderPlugin::Action)
        expect(action.action_name).to eq("TestAction")
      end

      context "when given non-local action name" do
        let(:actions) { ["Vagrant::Action::Builtin::Call"] }

        it "should load the existing action class" do
          builder = subject.action(action_name)
          action = builder.stack.first.first
          expect(action).to eq(Vagrant::Action::Builtin::Call)
        end
      end
    end

    describe "#capability" do
      let(:cap_name) { "test_cap" }
      let(:response) { double("response", result: result.to_json) }
      let(:result) { nil }

      before do
        allow(subject).to receive(:name).and_return("dummy_provider")
        allow(client).to receive(:provider_capability).and_return(response)
      end

      it "should call the plugin client" do
        expect(client).to receive(:provider_capability).
          with(instance_of(Vagrant::Proto::ProviderCapabilityRequest))
          .and_return(response)
        subject.capability(cap_name)
      end

      it "should deserialize result" do
        expect(subject.capability(cap_name)).to eq(result)
      end

      context "when hash value is returned" do
        let(:result) { {key: "value"} }

        it "should return indifferent access hash" do
          r = subject.capability(cap_name)
          expect(r[:key]).to eq(result[:key])
          expect(r).to be_a(Vagrant::Util::HashWithIndifferentAccess)
        end
      end

      context "when arguments are provided" do
        let(:args) { ["arg1", {"key" => "value"}] }

        it "should serialize arguments when sent to plugin client" do
          expect(client).to receive(:provider_capability) do |req|
            expect(req.arguments).to eq(args.to_json)
            response
          end
          subject.capability(cap_name, *args)
        end
      end
    end

    describe "#is_installed?" do
      it "should call plugin client" do
        expect(client).to receive(:is_installed).and_return(double("response", result: true))
        expect(subject.is_installed?).to eq(true)
      end
    end

    describe "#is_usable?" do
      it "should call plugin client" do
        expect(client).to receive(:is_usable).and_return(double("response", result: true))
        expect(subject.is_usable?).to eq(true)
      end
    end

    describe "#machine_id_changed" do
      it "should call plugin client" do
        expect(client).to receive(:machine_id_changed).and_return(double("response", result: true))
        expect(subject.machine_id_changed).to be_nil
      end
    end

    describe "#ssh_info" do
      let(:response) {
        Vagrant::Proto::MachineSshInfo.new(
          host: "localhost",
          port: 2222,
          private_key_path: "/key/path",
          username: "vagrant"
        )
      }

      before { allow(client).to receive(:ssh_info).and_return(response) }

      it "should return hash with indifferent access result" do
        expect(subject.ssh_info).to be_a(Vagrant::Util::HashWithIndifferentAccess)
      end

      it "should include ssh information" do
        result = subject.ssh_info
        expect(result[:host]).to eq(response.host)
        expect(result[:port]).to eq(response.port)
        expect(result[:private_key_path]).to eq(response.private_key_path)
        expect(result[:username]).to eq(response.username)
      end
    end

    describe "#state" do
      let(:response) {
        Vagrant::Proto::MachineState.new(
          id: "machine-id",
          short_description: "running",
          long_description: "it's really running"
        )
      }

      before { allow(client).to receive(:state).and_return(response) }

      it "should return a MachineState instance" do
        expect(subject.state).to be_a(Vagrant::MachineState)
      end

      it "should set the state attributes" do
        result = subject.state
        expect(result.id).to eq(response.id)
        expect(result.short_description).to eq(response.short_description)
        expect(result.long_description).to eq(response.long_description)
      end
    end
  end
end
