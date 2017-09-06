require_relative "../../../../base"
require_relative "../../support/shared/config"
require_relative "shared"

require Vagrant.source_root.join("plugins/provisioners/ansible/config/guest")

describe VagrantPlugins::Ansible::Config::Guest do
  include_context "unit"

  subject { described_class.new }

  # FIXME: machine.ui.warn stub is not working as expected...
  let(:machine) { double("machine", env: Vagrant::Environment.new) }

  let(:communicator) { double("communicator") }
  let(:existing_file) { "this/path/is/a/stub" }

  it "supports a list of options" do
    supported_options = %w(
                            become
                            become_user
                            compatibility_mode
                            config_file
                            extra_vars
                            galaxy_command
                            galaxy_role_file
                            galaxy_roles_path
                            groups
                            host_vars
                            install
                            install_mode
                            inventory_path
                            limit
                            pip_args
                            playbook
                            playbook_command
                            provisioning_path
                            raw_arguments
                            skip_tags
                            start_at_task
                            sudo
                            sudo_user
                            tags
                            tmp_path
                            vault_password_file
                            verbose
                            version
                          )

    expect(get_provisioner_option_names(described_class)).to eql(supported_options)
  end

  describe "default options handling" do
    it_behaves_like "options shared by both Ansible provisioners"

    it "assigns default values to unset guest-specific options" do
      subject.finalize!

      expect(subject.install).to be(true)
      expect(subject.install_mode).to eql(:default)
      expect(subject.provisioning_path).to eql("/vagrant")
      expect(subject.tmp_path).to eql("/tmp/vagrant-ansible")
    end
  end

  describe "#validate" do
    before do
      subject.playbook = existing_file
    end

    it_behaves_like "an Ansible provisioner", "/vagrant", "local"

    it "falls back to :default install_mode for any invalid setting" do
      subject.install_mode = "from_source"
      subject.finalize!

      result = subject.validate(machine)
      expect(subject.install_mode).to eql(:default)
    end

    it "supports :pip install_mode" do
      subject.install_mode = "pip"
      subject.finalize!

      result = subject.validate(machine)
      expect(subject.install_mode).to eql(:pip)
    end

    it "supports :pip_args_only install_mode" do
      subject.install_mode = "pip_args_only"
      subject.finalize!

      result = subject.validate(machine)
      expect(subject.install_mode).to eql(:pip_args_only)
    end
  end

end
