require_relative "../../../../base"
require_relative "../../support/shared/config"
require_relative "shared"

require Vagrant.source_root.join("plugins/provisioners/ansible/config/host")

describe VagrantPlugins::Ansible::Config::Host, :skip_windows => true do
  include_context "unit"

  subject { described_class.new }

  let(:machine) { double("machine", env: Vagrant::Environment.new) }
  let(:existing_file) { File.expand_path(__FILE__) }

  it "supports a list of options" do
    supported_options = %w(
                            ask_become_pass
                            ask_sudo_pass
                            ask_vault_pass
                            become
                            become_user
                            compatibility_mode
                            config_file
                            extra_vars
                            force_remote_user
                            galaxy_command
                            galaxy_role_file
                            galaxy_roles_path
                            groups
                            host_key_checking
                            host_vars
                            inventory_path
                            limit
                            playbook
                            playbook_command
                            raw_arguments
                            raw_ssh_args
                            skip_tags
                            start_at_task
                            sudo
                            sudo_user
                            tags
                            vault_password_file
                            verbose
                            version
                          )

    expect(get_provisioner_option_names(described_class)).to eql(supported_options)
  end

  describe "default options handling" do
    it_behaves_like "options shared by both Ansible provisioners"

    it "assigns default values to unset host-specific options" do
      subject.finalize!

      expect(subject.ask_become_pass).to be(false)
      expect(subject.ask_sudo_pass).to be(false)      # deprecated
      expect(subject.ask_vault_pass).to be(false)
      expect(subject.force_remote_user).to be(true)
      expect(subject.host_key_checking).to be(false)
      expect(subject.raw_ssh_args).to be_nil
    end
  end

  describe "force_remote_user option" do
    it_behaves_like "any VagrantConfigProvisioner strict boolean attribute", :force_remote_user, true
  end
  describe "host_key_checking option" do
    it_behaves_like "any VagrantConfigProvisioner strict boolean attribute", :host_key_checking, false
  end
  describe "ask_become_pass option" do
    it_behaves_like "any VagrantConfigProvisioner strict boolean attribute", :ask_become_pass, false
  end
  describe "ask_sudo_pass option" do
    before do
      # Filter the deprecation notice
      allow($stdout).to receive(:puts)
    end
    it_behaves_like "any VagrantConfigProvisioner strict boolean attribute", :ask_sudo_pass, false
    it_behaves_like "any deprecated option", :ask_sudo_pass, :ask_become_pass, true
  end
  describe "ask_vault_pass option" do
    it_behaves_like "any VagrantConfigProvisioner strict boolean attribute", :ask_vault_pass, false
  end

  describe "#validate" do
    before do
      subject.playbook = existing_file
    end

    it_behaves_like "an Ansible provisioner", "", "remote"

    it "returns an error if the raw_ssh_args is of the wrong data type" do
      subject.raw_ssh_args = { arg1: 1, arg2: "foo" }
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible remote provisioner"]).to eql([
        I18n.t("vagrant.provisioners.ansible.errors.raw_ssh_args_invalid",
               type:  subject.raw_ssh_args.class.to_s,
               value: subject.raw_ssh_args.to_s)
      ])
    end

    it "converts a raw_ssh_args option defined as a String into an Array" do
      subject.raw_arguments = "-o ControlMaster=no"
      subject.finalize!

      result = subject.validate(machine)
      expect(subject.raw_arguments).to eql(["-o ControlMaster=no"])
    end

  end

end
