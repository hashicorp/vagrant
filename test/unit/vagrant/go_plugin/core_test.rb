require_relative "../../base"

describe Vagrant::GoPlugin::GRPCPlugin do
  let(:client) { double("client") }
  let(:subject) { Class.new.tap { |c| c.include(described_class) } }

  describe ".plugin_client=" do
    it "should set the plugin client" do
      expect(subject.plugin_client = client).to eq(client)
      expect(subject.plugin_client).to eq(client)
    end

    it "should error if plugin is already set" do
      subject.plugin_client = client
      expect { subject.plugin_client = client }.
        to raise_error(ArgumentError)
    end
  end

  describe ".plugin_client" do
    it "should return nil when client has not been set" do
      expect(subject.plugin_client).to be_nil
    end

    it "should return client when it has been set" do
      subject.plugin_client = client
      expect(subject.plugin_client).to eq(client)
    end
  end

  describe "#plugin_client" do
    it "should be nil when client has not been set" do
      expect(subject.new.plugin_client).to be_nil
    end

    it "should return client when client has been set" do
      subject.plugin_client = client
      expect(subject.new.plugin_client).to eq(client)
    end
  end
end
