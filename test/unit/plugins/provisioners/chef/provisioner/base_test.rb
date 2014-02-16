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
      machine.stub(:env).and_return(env)
      env.stub(:root_path).and_return(root_path)
    end

    it "returns absolute path as is" do
      config.should_receive(:encrypted_data_bag_secret_key_path).
        and_return("/foo/bar")
      expect(subject.encrypted_data_bag_secret_key_path).to eq "/foo/bar"
    end

    it "returns relative path joined to root_path" do
      config.should_receive(:encrypted_data_bag_secret_key_path).
        and_return("secret")
      expect(subject.encrypted_data_bag_secret_key_path).to eq "/my/root/secret"
    end
  end

  describe "#guest_encrypted_data_bag_secret_key_path" do
    it "returns nil if host path is not configured" do
      config.stub(:encrypted_data_bag_secret_key_path).and_return(nil)
      config.stub(:provisioning_path).and_return("/tmp/foo")
      expect(subject.guest_encrypted_data_bag_secret_key_path).to be_nil
    end

    it "returns path under config.provisioning_path" do
      config.stub(:encrypted_data_bag_secret_key_path).and_return("secret")
      config.stub(:provisioning_path).and_return("/tmp/foo")
      expect(File.dirname(subject.guest_encrypted_data_bag_secret_key_path)).
        to eq "/tmp/foo"
    end
  end
end
