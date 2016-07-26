require_relative "../../../../base"

require Vagrant.source_root.join("plugins/provisioners/chef/provisioner/base")

describe VagrantPlugins::Chef::Provisioner::Base do
  include_context "unit"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }
  let(:config)  { double("config") }

  subject { described_class.new(machine, config) }

  before do
    allow(config).to receive(:node_name)
    allow(config).to receive(:node_name=)
  end

  describe "#node_name" do
    let(:env) { double("env") }
    let(:root_path) { "/my/root" }

    before do
      allow(machine).to receive(:env).and_return(env)
      allow(env).to receive(:root_path).and_return(root_path)
    end

    it "defaults to node_name if given" do
      config = OpenStruct.new(node_name: "name")
      instance = described_class.new(machine, config)
      expect(instance.config.node_name).to eq("name")
    end

    it "defaults to hostname if given" do
      machine.config.vm.hostname = "by.hostname"
      instance = described_class.new(machine, OpenStruct.new)
      expect(instance.config.node_name).to eq("by.hostname")
    end

    it "generates a random name if no hostname or node_name is given" do
      config = OpenStruct.new(node_name: nil)
      machine.config.vm.hostname = nil
      instance = described_class.new(machine, OpenStruct.new)
      expect(instance.config.node_name).to match(/vagrant\-.+/)
    end
  end

  describe "#encrypted_data_bag_secret_key_path" do
    let(:env) { double("env") }
    let(:root_path) { "/my/root" }

    before do
      allow(machine).to receive(:env).and_return(env)
      allow(env).to receive(:root_path).and_return(root_path)
    end

    it "returns absolute path as is" do
      expect(config).to receive(:encrypted_data_bag_secret_key_path).
        and_return("/foo/bar")
      expect(subject.encrypted_data_bag_secret_key_path).to eq "/foo/bar"
    end

    it "returns relative path joined to root_path" do
      expect(config).to receive(:encrypted_data_bag_secret_key_path).
        and_return("secret")
      expect(subject.encrypted_data_bag_secret_key_path).to eq "/my/root/secret"
    end
  end

  describe "#guest_encrypted_data_bag_secret_key_path" do
    it "returns nil if host path is not configured" do
      allow(config).to receive(:encrypted_data_bag_secret_key_path).and_return(nil)
      allow(config).to receive(:provisioning_path).and_return("/tmp/foo")
      expect(subject.guest_encrypted_data_bag_secret_key_path).to be_nil
    end

    it "returns path under config.provisioning_path" do
      allow(config).to receive(:encrypted_data_bag_secret_key_path).and_return("secret")
      allow(config).to receive(:provisioning_path).and_return("/tmp/foo")
      expect(File.dirname(subject.guest_encrypted_data_bag_secret_key_path)).
        to eq "/tmp/foo"
    end
  end
end
