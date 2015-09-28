require_relative "../../../../base"

require Vagrant.source_root.join("plugins/provisioners/chef/config/chef_solo")

describe VagrantPlugins::Chef::Config::ChefSolo do
  include_context "unit"

  subject { described_class.new }

  let(:machine) { double("machine") }

  describe "#cookbooks_path" do
    it "defaults to something" do
      subject.finalize!
      expect(subject.cookbooks_path).to eq([
        [:host, "cookbooks"],
        [:vm, "cookbooks"],
      ])
    end
  end

  describe "#data_bags_path" do
    it "defaults to an empty array" do
      subject.finalize!
      expect(subject.data_bags_path).to be_a(Array)
      expect(subject.data_bags_path).to be_empty
    end
  end

  describe "#environments_path" do
    it "defaults to an empty array" do
      subject.finalize!
      expect(subject.environments_path).to be_a(Array)
      expect(subject.environments_path).to be_empty
    end

    it "merges deeply nested paths" do
      subject.environments_path = ["/foo", "/bar", ["/zip"]]
      subject.finalize!
      expect(subject.environments_path)
        .to eq([:host, :host, :host].zip %w(/foo /bar /zip))
    end
  end

  describe "#recipe_url" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.recipe_url).to be(nil)
    end
  end

  describe "#roles_path" do
    it "defaults to an empty array" do
      subject.finalize!
      expect(subject.roles_path).to be_a(Array)
      expect(subject.roles_path).to be_empty
    end
  end

  describe "#nodes_path" do
    it "defaults to an empty array" do
      subject.finalize!
      expect(subject.nodes_path).to be_a(Array)
      expect(subject.nodes_path).to be_empty
    end
  end

  describe "#synced_folder_type" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.synced_folder_type).to be(nil)
    end
  end

  describe "#validate" do
    before do
      allow(machine).to receive(:env)
        .and_return(double("env",
          root_path: "",
        ))

      subject.cookbooks_path = ["/cookbooks", "/more/cookbooks"]
    end

    let(:result) { subject.validate(machine) }
    let(:errors) { result["chef solo provisioner"] }

    context "when the cookbooks_path is nil" do
      it "returns an error" do
        subject.cookbooks_path = nil
        subject.finalize!
        expect(errors).to eq [I18n.t("vagrant.config.chef.cookbooks_path_empty")]
      end
    end

    context "when the cookbooks_path is an empty array" do
      it "returns an error" do
        subject.cookbooks_path = []
        subject.finalize!
        expect(errors).to eq [I18n.t("vagrant.config.chef.cookbooks_path_empty")]
      end
    end

    context "when the cookbooks_path is an array with nil" do
      it "returns an error" do
        subject.cookbooks_path = [nil, nil]
        subject.finalize!
        expect(errors).to eq [I18n.t("vagrant.config.chef.cookbooks_path_empty")]
      end
    end

    context "when environments is given" do
      before do
        subject.environment = "production"
      end

      context "when the environments_path is nil" do
        it "returns an error" do
          subject.environments_path = nil
          subject.finalize!
          expect(errors).to eq [I18n.t("vagrant.config.chef.environment_path_required")]
        end
      end

      context "when the environments_path is an empty array" do
        it "returns an error" do
          subject.environments_path = []
          subject.finalize!
          expect(errors).to eq [I18n.t("vagrant.config.chef.environment_path_required")]
        end
      end

      context "when the environments_path is an array with nil" do
        it "returns an error" do
          subject.environments_path = [nil, nil]
          subject.finalize!
          expect(errors).to eq [I18n.t("vagrant.config.chef.environment_path_required")]
        end
      end

      context "when the environments_path does not exist" do
        it "returns an error" do
          env_path = "/path/to/environments/that/will/never/exist"
          subject.environments_path = env_path
          subject.finalize!
          expect(errors).to eq [
            I18n.t("vagrant.config.chef.environment_path_missing",
              path: env_path
            )
          ]
        end
      end
    end
  end
end
