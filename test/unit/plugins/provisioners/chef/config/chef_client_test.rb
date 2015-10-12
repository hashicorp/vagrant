require_relative "../../../../base"

require Vagrant.source_root.join("plugins/provisioners/chef/config/chef_client")

describe VagrantPlugins::Chef::Config::ChefClient do
  include_context "unit"

  subject { described_class.new }

  let(:machine) { double("machine") }

  describe "#chef_server_url" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.chef_server_url).to be(nil)
    end
  end

  describe "#client_key_path" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.client_key_path).to be(nil)
    end
  end

  describe "#delete_client" do
    it "defaults to false" do
      subject.finalize!
      expect(subject.delete_client).to be(false)
    end
  end

  describe "#delete_node" do
    it "defaults to false" do
      subject.finalize!
      expect(subject.delete_node).to be(false)
    end
  end

  describe "#validation_key_path" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.validation_key_path).to be(nil)
    end
  end

  describe "#validation_client_name" do
    it "defaults to chef-validator" do
      subject.finalize!
      expect(subject.validation_client_name).to eq("chef-validator")
    end
  end

  describe "#validate" do
    before do
      allow(machine).to receive(:env)
        .and_return(double("env",
          root_path: "",
        ))

      subject.chef_server_url = "https://example.com"
      subject.validation_key_path = "/path/to/key.pem"
    end

    let(:result) { subject.validate(machine) }
    let(:errors) { result["chef client provisioner"] }

    context "when the chef_server_url is nil" do
      it "returns an error" do
        subject.chef_server_url = nil
        subject.finalize!
        expect(errors).to eq([I18n.t("vagrant.config.chef.server_url_empty")])
      end
    end

    context "when the chef_server_url is blank" do
      it "returns an error" do
        subject.chef_server_url = "  "
        subject.finalize!
        expect(errors).to eq([I18n.t("vagrant.config.chef.server_url_empty")])
      end
    end

    context "when the validation_key_path is nil" do
      it "returns an error" do
        subject.validation_key_path = nil
        subject.finalize!
        expect(errors).to eq([I18n.t("vagrant.config.chef.validation_key_path")])
      end
    end

    context "when the validation_key_path is blank" do
      it "returns an error" do
        subject.validation_key_path = "  "
        subject.finalize!
        expect(errors).to eq([I18n.t("vagrant.config.chef.validation_key_path")])
      end
    end

    context "when #delete_client is given" do
      before { subject.delete_client = true }

      context "when knife does not exist" do
        before do
          allow(Vagrant::Util::Which)
            .to receive(:which)
            .with("knife")
            .and_return(nil)
        end

        it "returns an error" do
          subject.finalize!
          expect(errors).to eq([I18n.t("vagrant.chef_config_knife_not_found")])
        end
      end
    end

    context "when #delete_node is given" do
      before { subject.delete_node = true }

      context "when knife does not exist" do
        before do
          allow(Vagrant::Util::Which)
            .to receive(:which)
            .with("knife")
            .and_return(nil)
        end

        it "returns an error" do
          subject.finalize!
          expect(errors).to eq([I18n.t("vagrant.chef_config_knife_not_found")])
        end
      end
    end
  end
end
