require_relative "../../../../base"

require Vagrant.source_root.join("plugins/provisioners/chef/config/chef_apply")

describe VagrantPlugins::Chef::Config::ChefApply do
  include_context "unit"

  subject { described_class.new }

  let(:machine) { double("machine") }

  def chef_error(key, options = {})
    I18n.t("vagrant.provisioners.chef.#{key}", options)
  end

  describe "#recipe" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.recipe).to be(nil)
    end
  end

  describe "#upload_path" do
    it "defaults to /tmp/vagrant-chef-apply.rb" do
      subject.finalize!
      expect(subject.upload_path).to eq("/tmp/vagrant-chef-apply")
    end
  end

  describe "#validate" do
    before do
      allow(machine).to receive(:env)
        .and_return(double("env",
          root_path: "",
        ))

      subject.recipe = <<-EOH
        package "foo"
      EOH
    end

    let(:result) { subject.validate(machine) }
    let(:errors) { result["chef apply provisioner"] }

    context "when the recipe is nil" do
      it "returns an error" do
        subject.recipe = nil
        subject.finalize!
        expect(errors).to include chef_error("recipe_empty")
      end
    end

    context "when the recipe is empty" do
      it "returns an error" do
        subject.recipe = "  "
        subject.finalize!
        expect(errors).to include chef_error("recipe_empty")
      end
    end

    context "when the log_level is an empty array" do
      it "returns an error" do
        subject.log_level = "  "
        subject.finalize!
        expect(errors).to include chef_error("log_level_empty")
      end
    end

    context "when the upload_path is nil" do
      it "returns an error" do
        subject.upload_path = nil
        subject.finalize!
        expect(errors).to include chef_error("upload_path_empty")
      end
    end

    context "when the upload_path is an empty array" do
      it "returns an error" do
        subject.upload_path = "  "
        subject.finalize!
        expect(errors).to include chef_error("upload_path_empty")
      end
    end
  end
end
