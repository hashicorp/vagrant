require_relative "../../base"

describe Vagrant::GoPlugin::ConfigPlugin do
  let(:client) { double("client") }

  describe ".generate_config" do
    let(:parent_name) { "test" }
    let(:parent_klass) { double("parent_klass") }
    let(:parent_type) { "dummy" }
    let(:attributes_response) {
      double("attributes_response",
        items: attributes)
    }
    let(:attributes) { [] }

    before do
      allow(parent_klass).to receive(:config)
      allow(client).to receive(:config_attributes).
        and_return(attributes_response)
    end

    it "should register a new config class" do
      expect(parent_klass).to receive(:config).
        with(parent_name, parent_type) { |&block|
        expect(block.call.ancestors).to include(Vagrant::GoPlugin::ConfigPlugin::Config)
      }
      described_class.generate_config(client, parent_name, parent_klass, parent_type)
    end

    it "should register the client within the class" do
      expect(parent_klass).to receive(:config).
        with(parent_name, parent_type) { |&block|
        expect(block.call.plugin_client).to eq(client)
      }
      described_class.generate_config(client, parent_name, parent_klass, parent_type)
    end

    context "when attributes are provided" do
      let(:attributes) { ["a_one", "a_two"] }

      it "should add accessor instance methods to the class" do
        expect(parent_klass).to receive(:config).
          with(parent_name, parent_type) { |&block|
          expect(block.call.instance_methods).to include(:a_one)
          expect(block.call.instance_methods).to include(:a_two)
        }
        described_class.generate_config(client, parent_name, parent_klass, parent_type)
      end
    end
  end

  describe Vagrant::GoPlugin::ConfigPlugin::Config do
    let(:machine) { double("machine") }
    let(:subject) {
      c = Class.new(described_class)
      c.plugin_client = client
      c.new
    }

    describe "#validate" do
      let(:response) { double("response", items: errors) }
      let(:errors) { ["errors"] }

      before do
        allow(machine).to receive(:to_json).and_return("{}")
        allow(client).to receive(:config_validate).and_return(response)
      end

      it "should call client to validate" do
        expect(client).to receive(:config_validate).
          with(instance_of(Vagrant::Proto::Configuration)).
          and_return(response)
        subject.validate(machine)
      end

      it "should return list of validation errors" do
        expect(subject.validate(machine)).to eq(errors)
      end
    end

    describe "#finalize!" do
      let(:response) { double("response", data: result) }
      let(:result) { "null" }

      before do
        allow(client).to receive(:config_finalize).and_return(response)
      end

      it "should return the config instance" do
        expect(subject.finalize!).to eq(subject)
      end

      it "should call client to finalize" do
        expect(client).to receive(:config_finalize).
          with(instance_of(Vagrant::Proto::Configuration)).
          and_return(response)
        subject.finalize!
      end

      context "when configuration data is returned" do
        let(:result) {
          {attr1: true, attr2: "value"}.to_json
        }

        it "should create accessor methods to configuration data" do
          subject.finalize!
          expect(subject).to respond_to(:attr1)
          expect(subject).to respond_to(:attr2)
        end

        it "should return data from reader methods" do
          subject.finalize!
          expect(subject.attr1).to eq(true)
          expect(subject.attr2).to eq("value")
        end
      end

      describe "#local_data" do
        it "should return an empty hash" do
          expect(subject.local_data).to be_empty
        end

        context "with config attributes set" do
          let(:response) { double("response", data: result) }
          let(:result) { {attr1: true, attr2: "value"}.to_json }

          before do
            allow(client).to receive(:config_finalize).and_return(response)
            subject.finalize!
          end

          it "should return data values" do
            result = subject.local_data
            expect(result[:attr1]).to eq(true)
            expect(result[:attr2]).to eq("value")
          end
        end
      end
    end
  end
end
