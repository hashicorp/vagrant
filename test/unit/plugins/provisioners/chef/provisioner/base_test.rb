require_relative "../../../../base"

require Vagrant.source_root.join("plugins/provisioners/chef/provisioner/base")

describe VagrantPlugins::Chef::Provisioner::Base do
  include_context "unit"

  let(:machine) { double("machine") }
  let(:config)  { double("config") }

  subject { described_class.new(machine, config) }

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
