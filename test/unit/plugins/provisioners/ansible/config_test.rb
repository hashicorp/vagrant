require_relative "../../../base"

require Vagrant.source_root.join("plugins/provisioners/ansible/config")

describe VagrantPlugins::Ansible::Config do
  include_context "unit"

  subject { described_class.new }

  let(:machine) { double("machine", env: Vagrant::Environment.new) }
  let(:file_that_exists) { File.expand_path(__FILE__) }

  describe "#validate" do
    it "returns an error if playbook file does not exist" do
      non_existing_file = "/this/does/not/exist"

      subject.playbook = non_existing_file
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible provisioner"]).to eql([
        I18n.t("vagrant.provisioners.ansible.playbook_path_invalid",
               :path => non_existing_file)
      ])
    end

    it "returns an error if inventory_path is specified, but does not exist" do
      non_existing_file = "/this/does/not/exist"

      subject.playbook = file_that_exists
      subject.inventory_path = non_existing_file
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible provisioner"]).to eql([
        I18n.t("vagrant.provisioners.ansible.inventory_path_invalid",
               :path => non_existing_file)
      ])
    end

  end
end
